import SwiftUI

enum WishTone: Int, CaseIterable, Identifiable {
    case formal       = 0
    case professional = 1
    case warm         = 2
    case friendly     = 3
    case playful      = 4
    case funny        = 5

    var id: Int { rawValue }

    var label: String {
        switch self {
        case .formal:       return "Formal"
        case .professional: return "Professional"
        case .warm:         return "Warm"
        case .friendly:     return "Friendly"
        case .playful:      return "Playful"
        case .funny:        return "Funny"
        }
    }

    var emoji: String {
        switch self {
        case .formal:       return "🎩"
        case .professional: return "💼"
        case .warm:         return "🤍"
        case .friendly:     return "😊"
        case .playful:      return "✨"
        case .funny:        return "😄"
        }
    }

    var color: Color {
        switch self {
        case .formal:       return Color(hex: 0x3b82f6)
        case .professional: return Color(hex: 0x6366f1)
        case .warm:         return Color(hex: 0x8b5cf6)
        case .friendly:     return Color(hex: 0xa855f7)
        case .playful:      return Color(hex: 0xc084fc)
        case .funny:        return Color(hex: 0xe879f9)
        }
    }

    var apiInstruction: String {
        switch self {
        case .formal:
            return "Write in a formal, respectful, eloquent tone. Suitable for official or ceremonial relationships. Use refined language."
        case .professional:
            return "Write in a polished, professional tone. Appropriate for colleagues, clients, or business acquaintances. Courteous and composed."
        case .warm:
            return "Write in a warm, sincere, heartfelt tone. Express genuine care and affection without being overly casual."
        case .friendly:
            return "Write in a casual, friendly tone — like a good friend speaking naturally. Approachable and kind."
        case .playful:
            return "Write in a light, playful tone with cheerful energy and a touch of whimsy. Upbeat and fun."
        case .funny:
            return "Write in a humorous, witty tone with a clever joke or playful twist. Keep it tasteful and genuinely funny."
        }
    }
}
