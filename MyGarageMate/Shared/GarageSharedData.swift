import Foundation

/// Lightweight, process-safe bridge between the app and its widget/Live Activity
/// extension. The app writes a small Codable snapshot into the shared App Group
/// container; the extension reads it. This avoids sharing the SwiftData store
/// across processes while keeping widgets fast and always up to date.
enum GarageSharedData {
    static let appGroupID = "group.com.vpanev.mygaragemate"
    private static let snapshotKey = "garage.snapshot.v1"

    private static var defaults: UserDefaults? {
        UserDefaults(suiteName: appGroupID)
    }

    static func save(_ snapshot: GarageSnapshot) {
        guard let data = try? JSONEncoder().encode(snapshot) else { return }
        defaults?.set(data, forKey: snapshotKey)
    }

    static func load() -> GarageSnapshot? {
        guard let data = defaults?.data(forKey: snapshotKey) else { return nil }
        return try? JSONDecoder().decode(GarageSnapshot.self, from: data)
    }
}

/// A compact view of the garage that both processes understand.
struct GarageSnapshot: Codable {
    var generatedAt: Date
    var currencyCode: String
    var totalSpentThisYearMinor: Int
    var carCount: Int
    var nextReminder: ReminderSnapshot?
    var cars: [CarSnapshot]

    static let placeholder = GarageSnapshot(
        generatedAt: .now,
        currencyCode: "EUR",
        totalSpentThisYearMinor: 124_50,
        carCount: 2,
        nextReminder: ReminderSnapshot(
            id: UUID(),
            title: "Oil change",
            carName: "Golf GTI",
            symbolName: "oilcan.fill",
            dueDate: Calendar.current.date(byAdding: .day, value: 6, to: .now),
            dueMileage: nil,
            mileageUnit: "km",
            statusRawValue: "dueSoon"
        ),
        cars: [
            CarSnapshot(id: UUID(), name: "Golf GTI", statusRawValue: "dueSoon", spentThisYearMinor: 124_50),
            CarSnapshot(id: UUID(), name: "Model 3", statusRawValue: "allClear", spentThisYearMinor: 0)
        ]
    )
}

struct CarSnapshot: Codable, Identifiable {
    var id: UUID
    var name: String
    var statusRawValue: String
    var spentThisYearMinor: Int
}

struct ReminderSnapshot: Codable, Identifiable {
    var id: UUID
    var title: String
    var carName: String
    var symbolName: String
    var dueDate: Date?
    var dueMileage: Double?
    var mileageUnit: String
    var statusRawValue: String
}

// MARK: - Shared formatting / styling

enum SharedStatusStyle {
    /// RGBA components for a status raw value, usable from both UIKit/SwiftUI.
    static func color(for rawValue: String) -> (r: Double, g: Double, b: Double) {
        switch rawValue {
        case "overdue": (0.90, 0.27, 0.24)
        case "dueSoon": (0.95, 0.55, 0.15)
        case "allClear": (0.30, 0.72, 0.42)
        default: (0.18, 0.50, 0.95)
        }
    }
}

enum SharedCurrencyFormatter {
    static func string(fromMinor amountMinor: Int, currencyCode: String) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currencyCode
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2
        let major = Decimal(amountMinor) / 100
        return formatter.string(from: major as NSDecimalNumber) ?? "\(currencyCode) \(major)"
    }
}
