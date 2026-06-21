import Foundation
import SwiftData

enum EngineType: String, CaseIterable, Codable, Identifiable {
    case gasoline
    case diesel
    case hybrid
    case electric

    var id: String { rawValue }

    var title: String {
        switch self {
        case .gasoline: "Gasoline"
        case .diesel: "Diesel"
        case .hybrid: "Hybrid"
        case .electric: "Electric"
        }
    }

    var symbolName: String {
        switch self {
        case .gasoline: "fuelpump.fill"
        case .diesel: "fuelpump"
        case .hybrid: "leaf.fill"
        case .electric: "bolt.car.fill"
        }
    }
}

enum CarHealthStatus: String, CaseIterable, Codable, Identifiable {
    case overdue
    case dueSoon
    case allClear
    case needsSetup

    var id: String { rawValue }

    var title: String {
        switch self {
        case .overdue: "Needs attention"
        case .dueSoon: "Due soon"
        case .allClear: "All clear"
        case .needsSetup: "Set up reminders"
        }
    }

    var shortTitle: String {
        switch self {
        case .overdue: "Attention"
        case .dueSoon: "Due soon"
        case .allClear: "Clear"
        case .needsSetup: "Set up"
        }
    }

    var symbolName: String {
        switch self {
        case .overdue: "exclamationmark.triangle.fill"
        case .dueSoon: "clock.badge.exclamationmark.fill"
        case .allClear: "checkmark.seal.fill"
        case .needsSetup: "bell.badge.fill"
        }
    }
}

@Model
final class Car {
    var id: UUID
    var make: String
    var model: String
    var year: Int
    var trim: String?
    var plateNumber: String?
    var vin: String?
    var currentMileage: Double
    var mileageUnit: String
    var engineTypeRawValue: String = EngineType.gasoline.rawValue
    var photoData: Data?
    var createdAt: Date
    var owner: UserProfile?

    @Relationship(deleteRule: .cascade, inverse: \ServiceRecord.car)
    var serviceRecords: [ServiceRecord] = []

    @Relationship(deleteRule: .cascade, inverse: \CarReminder.car)
    var reminders: [CarReminder] = []

    @Relationship(deleteRule: .cascade, inverse: \MechanicNote.car)
    var mechanicNotes: [MechanicNote] = []

    init(
        id: UUID = UUID(),
        make: String,
        model: String,
        year: Int,
        trim: String? = nil,
        plateNumber: String? = nil,
        vin: String? = nil,
        currentMileage: Double = 0,
        mileageUnit: String = "km",
        engineType: EngineType = .gasoline,
        photoData: Data? = nil,
        createdAt: Date = .now,
        serviceRecords: [ServiceRecord] = [],
        reminders: [CarReminder] = [],
        mechanicNotes: [MechanicNote] = []
    ) {
        self.id = id
        self.make = make
        self.model = model
        self.year = year
        self.trim = trim
        self.plateNumber = plateNumber
        self.vin = vin
        self.currentMileage = currentMileage
        self.mileageUnit = mileageUnit
        self.engineTypeRawValue = engineType.rawValue
        self.photoData = photoData
        self.createdAt = createdAt
        self.serviceRecords = serviceRecords
        self.reminders = reminders
        self.mechanicNotes = mechanicNotes
    }

    var displayName: String {
        "\(year) \(make) \(model)"
    }

    var engineType: EngineType {
        get { EngineType(rawValue: engineTypeRawValue) ?? .gasoline }
        set { engineTypeRawValue = newValue.rawValue }
    }

    var serviceRecordsNewestFirst: [ServiceRecord] {
        serviceRecords.sorted { $0.date > $1.date }
    }

    var notesNewestFirst: [MechanicNote] {
        mechanicNotes.sorted { $0.date > $1.date }
    }

    var upcomingReminders: [CarReminder] {
        reminders.filter { !$0.isCompleted }.sorted(by: CarReminder.sortUpcoming)
    }

    var nextImportantReminder: CarReminder? {
        upcomingReminders.first
    }

    var lastService: ServiceRecord? {
        serviceRecordsNewestFirst.first
    }

    var healthStatus: CarHealthStatus {
        guard !reminders.isEmpty || !serviceRecords.isEmpty else {
            return .needsSetup
        }

        let activeReminders = reminders.filter { !$0.isCompleted }
        guard !activeReminders.isEmpty else {
            return .allClear
        }

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        let dueSoonCutoff = calendar.date(byAdding: .day, value: 30, to: today) ?? today

        if activeReminders.contains(where: { reminder in
            if let dueDate = reminder.dueDate, calendar.startOfDay(for: dueDate) < today {
                return true
            }
            if let dueMileage = reminder.dueMileage, dueMileage <= currentMileage {
                return true
            }
            return false
        }) {
            return .overdue
        }

        if activeReminders.contains(where: { reminder in
            if let dueDate = reminder.dueDate, dueDate <= dueSoonCutoff {
                return true
            }
            if let dueMileage = reminder.dueMileage, dueMileage <= currentMileage + 1_000 {
                return true
            }
            return false
        }) {
            return .dueSoon
        }

        return .allClear
    }

    var healthSubtitle: String {
        switch healthStatus {
        case .overdue:
            nextImportantReminder.map { "\($0.title) is overdue" } ?? "Review open reminders"
        case .dueSoon:
            nextImportantReminder.map { "\($0.title) is coming up" } ?? "Maintenance is coming up"
        case .allClear:
            "No urgent maintenance"
        case .needsSetup:
            "Add a reminder to track this car"
        }
    }

    func totalSpentThisYear(currencyCode: String, now: Date = .now) -> Int {
        serviceRecords
            .filter { record in
                record.currencyCode == currencyCode &&
                Calendar.current.isDate(record.date, equalTo: now, toGranularity: .year)
            }
            .reduce(0) { $0 + $1.amountMinor }
    }

    func totalSpent(currencyCode: String) -> Int {
        serviceRecords
            .filter { $0.currencyCode == currencyCode }
            .reduce(0) { $0 + $1.amountMinor }
    }

    func monthlySpend(currencyCode: String, monthCount: Int = 6, now: Date = .now) -> [MonthlySpend] {
        let calendar = Calendar.current
        let currentMonth = calendar.dateInterval(of: .month, for: now)?.start ?? now

        return (0..<monthCount).reversed().compactMap { offset in
            guard let monthStart = calendar.date(byAdding: .month, value: -offset, to: currentMonth),
                  let monthEnd = calendar.date(byAdding: .month, value: 1, to: monthStart) else {
                return nil
            }

            let amount = serviceRecords
                .filter { record in
                    record.currencyCode == currencyCode &&
                    record.date >= monthStart &&
                    record.date < monthEnd
                }
                .reduce(0) { $0 + $1.amountMinor }

            return MonthlySpend(monthStart: monthStart, amountMinor: amount)
        }
    }
}

struct MonthlySpend: Identifiable {
    let monthStart: Date
    let amountMinor: Int

    var id: Date { monthStart }

    var shortMonth: String {
        monthStart.formatted(.dateTime.month(.abbreviated))
    }
}
