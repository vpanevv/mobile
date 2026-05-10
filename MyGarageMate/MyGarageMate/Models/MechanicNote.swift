import Foundation
import SwiftData

enum NotePriority: String, CaseIterable, Codable, Identifiable {
    case low
    case medium
    case high

    var id: String { rawValue }

    var title: String {
        switch self {
        case .low: "Low"
        case .medium: "Medium"
        case .high: "High"
        }
    }

    var symbolName: String {
        switch self {
        case .low: "text.badge.checkmark"
        case .medium: "exclamationmark.circle.fill"
        case .high: "exclamationmark.triangle.fill"
        }
    }
}

@Model
final class MechanicNote {
    var id: UUID
    var text: String
    var date: Date
    var mileage: Double?
    var priorityRawValue: String
    var createdAt: Date
    var car: Car?

    var priority: NotePriority {
        get { NotePriority(rawValue: priorityRawValue) ?? .medium }
        set { priorityRawValue = newValue.rawValue }
    }

    init(
        id: UUID = UUID(),
        text: String,
        date: Date = .now,
        mileage: Double? = nil,
        priority: NotePriority = .medium,
        createdAt: Date = .now
    ) {
        self.id = id
        self.text = text
        self.date = date
        self.mileage = mileage
        self.priorityRawValue = priority.rawValue
        self.createdAt = createdAt
    }
}
