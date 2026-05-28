import Foundation

enum HolidayType: String, CaseIterable, Identifiable {
    case birthday    = "Birthday"
    case nameDay     = "Name Day"
    case anniversary = "Anniversary"
    case graduation  = "Graduation"
    case newBaby     = "New Baby"
    case newJob      = "New Job"
    case christmas   = "Christmas"
    case newYear     = "New Year"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .birthday:    return "birthday.cake.fill"
        case .nameDay:     return "person.text.rectangle.fill"
        case .anniversary: return "heart.fill"
        case .graduation:  return "graduationcap.fill"
        case .newBaby:     return "heart.circle.fill"
        case .newJob:      return "briefcase.fill"
        case .christmas:   return "snowflake"
        case .newYear:     return "fireworks"
        }
    }

    var label: String { rawValue }

    var emoji: String {
        switch self {
        case .birthday:    return "🎂"
        case .nameDay:     return "🌸"
        case .anniversary: return "💑"
        case .graduation:  return "🎓"
        case .newBaby:     return "👶"
        case .newJob:      return "💼"
        case .christmas:   return "🎄"
        case .newYear:     return "🎆"
        }
    }
}
