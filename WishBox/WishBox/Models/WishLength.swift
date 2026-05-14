import SwiftUI

enum WishLength: String, CaseIterable, Identifiable {
    case short  = "Short"
    case medium = "Medium"
    case long   = "Long"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .short:  return "bubble.left.fill"
        case .medium: return "doc.text.fill"
        case .long:   return "envelope.fill"
        }
    }

    var subtitle: String {
        switch self {
        case .short:  return "SMS · ~1 sentence"
        case .medium: return "Message · 2–3 sentences"
        case .long:   return "Email · 4–6 sentences"
        }
    }

    var color: Color {
        switch self {
        case .short:  return Color(hex: 0x22d3ee)
        case .medium: return Color(hex: 0xa855f7)
        case .long:   return Color(hex: 0xf43f5e)
        }
    }

    var apiInstruction: String {
        switch self {
        case .short:  return "Keep it very short: exactly 1 sentence, max 20 words. Perfect for SMS."
        case .medium: return "Write 2 to 3 sentences. Warm but concise, suitable for a chat message."
        case .long:   return "Write 4 to 6 sentences with a proper opening, body, and closing. Suitable for an email or card."
        }
    }
}
