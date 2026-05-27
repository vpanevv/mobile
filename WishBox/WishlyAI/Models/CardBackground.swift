import SwiftUI

enum CardBackground: String, CaseIterable, Identifiable {
    case auroraPurple
    case sunsetRose
    case oceanGlass
    case midnightGold
    case festiveRed
    case springMint
    case cottonCandy
    case deepSpace
    case champagne
    case lavenderDream

    var id: String { rawValue }

    var name: String {
        switch self {
        case .auroraPurple:  return "Aurora"
        case .sunsetRose:    return "Sunset"
        case .oceanGlass:    return "Ocean"
        case .midnightGold:  return "Midnight"
        case .festiveRed:    return "Festive"
        case .springMint:    return "Spring"
        case .cottonCandy:   return "Candy"
        case .deepSpace:     return "Space"
        case .champagne:     return "Champagne"
        case .lavenderDream: return "Lavender"
        }
    }

    var gradient: LinearGradient {
        switch self {
        case .auroraPurple:
            return LinearGradient(
                colors: [Color(hex: 0x1a0533), Color(hex: 0x6b21a8), Color(hex: 0xc084fc)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
        case .sunsetRose:
            return LinearGradient(
                colors: [Color(hex: 0xf43f5e), Color(hex: 0xf59e0b)],
                startPoint: .top, endPoint: .bottom
            )
        case .oceanGlass:
            return LinearGradient(
                colors: [Color(hex: 0x0ea5e9), Color(hex: 0x22d3ee), Color(hex: 0xa5f3fc)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
        case .midnightGold:
            return LinearGradient(
                colors: [Color(hex: 0x0f172a), Color(hex: 0x1e293b), Color(hex: 0xeab308)],
                startPoint: .top, endPoint: .bottom
            )
        case .festiveRed:
            return LinearGradient(
                colors: [Color(hex: 0x7f1d1d), Color(hex: 0xdc2626), Color(hex: 0xfca5a5)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
        case .springMint:
            return LinearGradient(
                colors: [Color(hex: 0x065f46), Color(hex: 0x10b981), Color(hex: 0xa7f3d0)],
                startPoint: .top, endPoint: .bottom
            )
        case .cottonCandy:
            return LinearGradient(
                colors: [Color(hex: 0xf9a8d4), Color(hex: 0xc4b5fd), Color(hex: 0xa5f3fc)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
        case .deepSpace:
            return LinearGradient(
                colors: [Color(hex: 0x000000), Color(hex: 0x1e1b4b), Color(hex: 0x4c1d95)],
                startPoint: .top, endPoint: .bottom
            )
        case .champagne:
            return LinearGradient(
                colors: [Color(hex: 0x78350f), Color(hex: 0xd4a574), Color(hex: 0xfef3c7)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
        case .lavenderDream:
            return LinearGradient(
                colors: [Color(hex: 0x6d28d9), Color(hex: 0xa78bfa), Color(hex: 0xede9fe)],
                startPoint: .top, endPoint: .bottom
            )
        }
    }

    /// Whether the card text should render light or dark
    var preferredTextColor: Color {
        switch self {
        case .auroraPurple, .midnightGold, .festiveRed, .deepSpace:
            return .white
        case .sunsetRose, .springMint:
            return .white
        case .oceanGlass:
            return Color(hex: 0x0c2a3b)
        case .cottonCandy:
            return Color(hex: 0x3b1f5e)
        case .champagne:
            return Color(hex: 0x3b2106)
        case .lavenderDream:
            return .white
        }
    }
}

