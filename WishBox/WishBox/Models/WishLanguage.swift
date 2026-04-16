import Foundation

enum WishLanguage: String, CaseIterable, Identifiable {
    case english    = "English"
    case bulgarian  = "Bulgarian"
    case spanish    = "Spanish"
    case french     = "French"
    case german     = "German"
    case italian    = "Italian"

    var id: String { rawValue }

    var flag: String {
        switch self {
        case .english:   return "🇬🇧"
        case .bulgarian: return "🇧🇬"
        case .spanish:   return "🇪🇸"
        case .french:    return "🇫🇷"
        case .german:    return "🇩🇪"
        case .italian:   return "🇮🇹"
        }
    }

    var label: String { rawValue }

    /// The instruction appended to the API prompt so the model replies in the right language.
    var promptInstruction: String {
        switch self {
        case .english:   return "Write the wish in English."
        case .bulgarian: return "Напиши пожеланието на български език."
        case .spanish:   return "Escribe el deseo en español."
        case .french:    return "Écris le vœu en français."
        case .german:    return "Schreibe den Wunsch auf Deutsch."
        case .italian:   return "Scrivi il desiderio in italiano."
        }
    }
}
