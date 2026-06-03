import Foundation
import SwiftUI

enum HolidayType: String, CaseIterable, Identifiable {
    case birthday    = "Birthday"
    case nameDay     = "Name Day"
    case anniversary = "Anniversary"
    case wedding     = "Wedding"
    case graduation  = "Graduation"
    case newBaby     = "New Baby"
    case newJob      = "New Job"
    case christmas   = "Christmas"
    case newYear       = "New Year"
    case valentinesDay = "Valentine's Day"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .birthday:    return "birthday.cake.fill"
        case .nameDay:     return "person.text.rectangle.fill"
        case .anniversary: return "heart.fill"
        case .wedding:     return "sparkles"
        case .graduation:  return "graduationcap.fill"
        case .newBaby:     return "heart.circle.fill"
        case .newJob:      return "briefcase.fill"
        case .christmas:   return "snowflake"
        case .newYear:       return "fireworks"
        case .valentinesDay: return "heart.fill"
        }
    }

    var label: String { rawValue }

    var emoji: String {
        switch self {
        case .birthday:    return "🎂"
        case .nameDay:     return "🌸"
        case .anniversary: return "💑"
        case .wedding:     return "💍"
        case .graduation:  return "🎓"
        case .newBaby:     return "👶"
        case .newJob:      return "💼"
        case .christmas:   return "🎄"
        case .newYear:       return "🎆"
        case .valentinesDay: return "❤️"
        }
    }

    var accentColor: Color {
        switch self {
        case .birthday:    return Color(hex: 0xec4899)  // pink
        case .nameDay:     return Color(hex: 0xa78bfa)  // violet
        case .anniversary: return Color(hex: 0xf43f5e)  // rose
        case .wedding:     return Color(hex: 0xfbbf24)  // gold
        case .graduation:  return Color(hex: 0x10b981)  // emerald
        case .newBaby:     return Color(hex: 0x22d3ee)  // cyan
        case .newJob:      return Color(hex: 0x6366f1)  // indigo
        case .christmas:   return Color(hex: 0x22c55e)  // green
        case .newYear:       return Color(hex: 0xf59e0b)  // amber
        case .valentinesDay: return Color(hex: 0xf43f5e)  // rose-pink
        }
    }
}
