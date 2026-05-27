import SwiftUI

enum CardFont: String, CaseIterable, Identifiable {
    case rounded
    case serif
    case elegant
    case mono
    case handwritten

    var id: String { rawValue }

    var name: String {
        switch self {
        case .rounded:     return "Rounded"
        case .serif:       return "Serif"
        case .elegant:     return "Elegant"
        case .mono:        return "Mono"
        case .handwritten: return "Handwritten"
        }
    }

    var previewLabel: String { "Aa" }

    func font(size: CGFloat) -> Font {
        switch self {
        case .rounded:
            return .system(size: size, weight: .semibold, design: .rounded)
        case .serif:
            return .system(size: size, weight: .medium, design: .serif)
        case .elegant:
            // Snell Roundhand — built-in iOS cursive; fall back to rounded
            let descriptor = UIFontDescriptor(name: "SnellRoundhand", size: size)
            if UIFont(descriptor: descriptor, size: size).familyName != ".SF UI Text" {
                return .custom("SnellRoundhand", size: size)
            }
            return .system(size: size, weight: .semibold, design: .rounded)
        case .mono:
            return .system(size: size, weight: .medium, design: .monospaced)
        case .handwritten:
            // Bradley Hand — built-in iOS handwriting; fall back to rounded
            let descriptor = UIFontDescriptor(name: "BradleyHandITCTT-Bold", size: size)
            if UIFont(descriptor: descriptor, size: size).familyName != ".SF UI Text" {
                return .custom("BradleyHandITCTT-Bold", size: size)
            }
            return .system(size: size, weight: .semibold, design: .rounded)
        }
    }
}
