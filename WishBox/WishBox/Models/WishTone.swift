import SwiftUI

enum WishTone: String, CaseIterable, Identifiable {
    case heartfelt = "Heartfelt"
    case friendly  = "Friendly"
    case funny     = "Funny"
    case formal    = "Formal"
    case poetic    = "Poetic"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .heartfelt: return "heart.fill"
        case .friendly:  return "face.smiling.fill"
        case .funny:     return "theatermasks.fill"
        case .formal:    return "briefcase.fill"
        case .poetic:    return "text.quote"
        }
    }

    var color: Color {
        switch self {
        case .heartfelt: return Color(hex: 0xf43f5e)
        case .friendly:  return Color(hex: 0xf59e0b)
        case .funny:     return Color(hex: 0xa855f7)
        case .formal:    return Color(hex: 0x3b82f6)
        case .poetic:    return Color(hex: 0xc084fc)
        }
    }

    var description: String {
        switch self {
        case .heartfelt: return "Warm & sincere"
        case .friendly:  return "Casual & warm"
        case .funny:     return "Light & humorous"
        case .formal:    return "Professional"
        case .poetic:    return "Lyrical & beautiful"
        }
    }

    var apiInstruction: String {
        switch self {
        case .heartfelt: return "Write in a warm, sincere, emotionally touching tone. Express genuine care and deep feeling."
        case .friendly:  return "Write in a casual, upbeat, friendly tone — like a good friend texting. Natural and warm."
        case .funny:     return "Write in a light, humorous tone with a witty joke or playful twist. Keep it tasteful and fun."
        case .formal:    return "Write in a professional, respectful, eloquent tone. Suitable for colleagues or formal relationships."
        case .poetic:    return "Write in a lyrical, poetic style with beautiful imagery and flowing language. Metaphors welcome."
        }
    }
}
