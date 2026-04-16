import Foundation

enum HolidayType: String, CaseIterable, Identifiable {
    case birthday = "Birthday"
    case nameDay = "Name Day"
    case anniversary = "Anniversary"
    case newYear = "New Year"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .birthday: return "birthday.cake.fill"
        case .nameDay: return "person.text.rectangle.fill"
        case .anniversary: return "heart.fill"
        case .newYear: return "fireworks"
        }
    }

    var label: String { rawValue }
}
