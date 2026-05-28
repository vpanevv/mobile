import SwiftData
import Foundation

@Model
final class Person {
    @Attribute(.unique) var id: UUID
    var name: String
    var occasionRawValue: String   // HolidayType.rawValue
    var day: Int                   // 1...31
    var month: Int                 // 1...12
    var createdAt: Date
    var notificationID: String

    init(name: String, occasion: HolidayType, day: Int, month: Int) {
        self.id = UUID()
        self.name = name
        self.occasionRawValue = occasion.rawValue
        self.day = day
        self.month = month
        self.createdAt = Date()
        self.notificationID = UUID().uuidString
    }

    var occasion: HolidayType {
        HolidayType(rawValue: occasionRawValue) ?? .birthday
    }

    // Next occurrence of this day/month on or after today
    var nextOccurrence: Date {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        var comps = DateComponents()
        comps.month = month
        comps.day   = day

        // Try this year first
        comps.year = cal.component(.year, from: today)
        if let candidate = cal.date(from: comps), candidate >= today {
            return candidate
        }
        // Otherwise next year
        comps.year = cal.component(.year, from: today) + 1
        return cal.date(from: comps) ?? today
    }

    var daysUntil: Int {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        let next  = cal.startOfDay(for: nextOccurrence)
        return cal.dateComponents([.day], from: today, to: next).day ?? 0
    }

    var monthName: String {
        DateFormatter().monthSymbols[month - 1]
    }

    // Short date label, e.g. "Mar 14"
    var shortDateLabel: String {
        let sym = Calendar.current.shortMonthSymbols[month - 1]
        return "\(sym) \(day)"
    }
}
