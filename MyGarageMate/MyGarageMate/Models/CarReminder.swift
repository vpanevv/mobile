import Foundation
import SwiftData

enum ReminderType: String, CaseIterable, Codable, Identifiable {
    case oilChange
    case insurance
    case inspection
    case tireChange
    case custom

    var id: String { rawValue }

    var title: String {
        switch self {
        case .oilChange: "Oil Change"
        case .insurance: "Insurance"
        case .inspection: "Inspection"
        case .tireChange: "Tire Change"
        case .custom: "Custom"
        }
    }

    var symbolName: String {
        switch self {
        case .oilChange: "oilcan.fill"
        case .insurance: "shield.lefthalf.filled"
        case .inspection: "checklist.checked"
        case .tireChange: "circle.hexagongrid.fill"
        case .custom: "bell.badge.fill"
        }
    }
}

@Model
final class CarReminder {
    var id: UUID
    var title: String
    var reminderTypeRawValue: String
    var dueDate: Date?
    var dueMileage: Double?
    var reminderDate: Date?
    var isCompleted: Bool
    var createdAt: Date
    var car: Car?

    var reminderType: ReminderType {
        get { ReminderType(rawValue: reminderTypeRawValue) ?? .custom }
        set { reminderTypeRawValue = newValue.rawValue }
    }

    init(
        id: UUID = UUID(),
        title: String,
        reminderType: ReminderType,
        dueDate: Date? = nil,
        dueMileage: Double? = nil,
        reminderDate: Date? = nil,
        isCompleted: Bool = false,
        createdAt: Date = .now
    ) {
        self.id = id
        self.title = title
        self.reminderTypeRawValue = reminderType.rawValue
        self.dueDate = dueDate
        self.dueMileage = dueMileage
        self.reminderDate = reminderDate
        self.isCompleted = isCompleted
        self.createdAt = createdAt
    }

    static func sortUpcoming(_ lhs: CarReminder, _ rhs: CarReminder) -> Bool {
        switch (lhs.dueDate, rhs.dueDate) {
        case let (left?, right?):
            if !Calendar.current.isDate(left, inSameDayAs: right) {
                return left < right
            }
        case (_?, nil):
            return true
        case (nil, _?):
            return false
        case (nil, nil):
            break
        }

        switch (lhs.dueMileage, rhs.dueMileage) {
        case let (left?, right?):
            return left < right
        case (_?, nil):
            return true
        case (nil, _?):
            return false
        case (nil, nil):
            return lhs.createdAt < rhs.createdAt
        }
    }
}
