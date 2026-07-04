import AppIntents
import Foundation
import SwiftData

// MARK: - Car entity

/// A car exposed to Siri / Shortcuts / Spotlight for natural parameter
/// resolution ("Log mileage for the 3 Series").
struct CarEntity: AppEntity {
    static let typeDisplayRepresentation: TypeDisplayRepresentation = "Car"
    static let defaultQuery = CarEntityQuery()

    var id: UUID
    var name: String
    var mileageUnit: String

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(name)")
    }
}

struct CarEntityQuery: EntityQuery {
    @MainActor
    func entities(for identifiers: [UUID]) async throws -> [CarEntity] {
        try allEntities().filter { identifiers.contains($0.id) }
    }

    @MainActor
    func suggestedEntities() async throws -> [CarEntity] {
        try allEntities()
    }

    @MainActor
    private func allEntities() throws -> [CarEntity] {
        let context = AppModelContainer.shared.mainContext
        let cars = try context.fetch(FetchDescriptor<Car>(sortBy: [SortDescriptor(\.createdAt)]))
        return cars.map { CarEntity(id: $0.id, name: $0.model, mileageUnit: $0.mileageUnit) }
    }
}

// MARK: - Errors

enum GarageIntentError: Error, CustomLocalizedStringResourceConvertible {
    case carNotFound
    case invalidMileage

    var localizedStringResource: LocalizedStringResource {
        switch self {
        case .carNotFound: "That car isn't in your garage anymore."
        case .invalidMileage: "Mileage must be a positive number."
        }
    }
}

// MARK: - Log mileage

struct LogMileageIntent: AppIntent {
    static let title: LocalizedStringResource = "Log Mileage"
    static let description = IntentDescription(
        "Update the current mileage for one of your cars.",
        categoryName: "Garage"
    )

    @Parameter(title: "Car")
    var car: CarEntity

    @Parameter(title: "Mileage", controlStyle: .field)
    var mileage: Double

    static var parameterSummary: some ParameterSummary {
        Summary("Log \(\.$mileage) on \(\.$car)")
    }

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        guard mileage > 0 else { throw GarageIntentError.invalidMileage }

        let context = AppModelContainer.shared.mainContext
        let cars = try context.fetch(FetchDescriptor<Car>())
        guard let target = cars.first(where: { $0.id == car.id }) else {
            throw GarageIntentError.carNotFound
        }

        target.currentMileage = mileage
        try context.save()

        // Keep widgets and the Lock Screen in sync immediately.
        let currency = (try? context.fetch(FetchDescriptor<UserProfile>()))?.first?.preferredCurrencyCode ?? "EUR"
        GarageSnapshotWriter.update(context: context, currencyCode: currency)

        let formatted = mileage.formatted(.number.precision(.fractionLength(0)))
        return .result(dialog: "Logged \(formatted) \(target.mileageUnit) on the \(target.model).")
    }
}

// MARK: - Next service

struct NextServiceIntent: AppIntent {
    static let title: LocalizedStringResource = "Next Service"
    static let description = IntentDescription(
        "Find out what's due next across your whole garage.",
        categoryName: "Garage"
    )

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let context = AppModelContainer.shared.mainContext
        let cars = try context.fetch(FetchDescriptor<Car>())

        let next = cars
            .flatMap { car in car.upcomingReminders.map { (reminder: $0, car: car) } }
            .sorted { CarReminder.sortUpcoming($0.reminder, $1.reminder) }
            .first

        guard let next else {
            return .result(dialog: "All clear — nothing is due across your garage.")
        }

        var dueText = ""
        if let dueDate = next.reminder.dueDate {
            dueText = " \(dueDate.formatted(.relative(presentation: .named)))"
        } else if let dueMileage = next.reminder.dueMileage {
            dueText = " at \(dueMileage.formatted(.number.precision(.fractionLength(0)))) \(next.car.mileageUnit)"
        }

        return .result(dialog: "Next up: \(next.reminder.title) for the \(next.car.model)\(dueText).")
    }
}

// MARK: - App Shortcuts

struct GarageShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: NextServiceIntent(),
            phrases: [
                "What's my next service in \(.applicationName)",
                "Next service in \(.applicationName)",
                "What's due in \(.applicationName)"
            ],
            shortTitle: "Next Service",
            systemImageName: "bell.badge.fill"
        )

        AppShortcut(
            intent: LogMileageIntent(),
            phrases: [
                "Log mileage in \(.applicationName)",
                "Update mileage in \(.applicationName)"
            ],
            shortTitle: "Log Mileage",
            systemImageName: "gauge.with.dots.needle.67percent"
        )
    }
}
