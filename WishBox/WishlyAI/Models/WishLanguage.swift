import Foundation

enum WishLanguage: String, CaseIterable, Identifiable {
    case english    = "English"
    case bulgarian  = "Bulgarian"
    case spanish    = "Spanish"
    case french     = "French"
    case german     = "German"
    case italian    = "Italian"
    case portuguese = "Portuguese"
    case dutch      = "Dutch"
    case polish     = "Polish"
    case russian    = "Russian"

    var id: String { rawValue }

    var flag: String {
        switch self {
        case .english:    return "🇬🇧"
        case .bulgarian:  return "🇧🇬"
        case .spanish:    return "🇪🇸"
        case .french:     return "🇫🇷"
        case .german:     return "🇩🇪"
        case .italian:    return "🇮🇹"
        case .portuguese: return "🇵🇹"
        case .dutch:      return "🇳🇱"
        case .polish:     return "🇵🇱"
        case .russian:    return "🇷🇺"
        }
    }

    /// Native language name shown in the picker tile
    var nativeName: String {
        switch self {
        case .english:    return "English"
        case .bulgarian:  return "Български"
        case .spanish:    return "Español"
        case .french:     return "Français"
        case .german:     return "Deutsch"
        case .italian:    return "Italiano"
        case .portuguese: return "Português"
        case .dutch:      return "Nederlands"
        case .polish:     return "Polski"
        case .russian:    return "Русский"
        }
    }

    var label: String { rawValue }

    /// Instruction appended to the API prompt so the model replies in the right language.
    var promptInstruction: String {
        switch self {
        case .english:    return "Write the wish in English."
        case .bulgarian:  return "Напиши пожеланието на български език."
        case .spanish:    return "Escribe el deseo en español."
        case .french:     return "Écris le vœu en français."
        case .german:     return "Schreibe den Wunsch auf Deutsch."
        case .italian:    return "Scrivi il desiderio in italiano."
        case .portuguese: return "Escreva o desejo em português."
        case .dutch:      return "Schrijf de wens in het Nederlands."
        case .polish:     return "Napisz życzenie po polsku."
        case .russian:    return "Напиши пожелание на русском языке."
        }
    }
}
