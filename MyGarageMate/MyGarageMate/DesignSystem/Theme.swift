import SwiftUI

/// Central design tokens for the Liquid Glass redesign.
///
/// Everything visual — spacing, radii, motion, and the signature color
/// system — flows from here so the whole app stays coherent.
enum Theme {
    // MARK: Spacing

    enum Spacing {
        static let xs: CGFloat = 4
        static let s: CGFloat = 8
        static let m: CGFloat = 12
        static let l: CGFloat = 16
        static let xl: CGFloat = 24
        static let xxl: CGFloat = 32
        static let xxxl: CGFloat = 44
    }

    // MARK: Corner radii

    enum Radius {
        static let chip: CGFloat = 12
        static let control: CGFloat = 18
        static let card: CGFloat = 26
        static let hero: CGFloat = 34
        static let sheet: CGFloat = 40
    }

    // MARK: Signature gradient tones

    /// The brand accent used as the primary tint across glass surfaces.
    static let accent = Color.accentColor

    /// Warm secondary used in gradients and chart series.
    static let ember = Color(red: 1.0, green: 0.45, blue: 0.30)

    /// Cool tertiary used for depth in ambient backgrounds.
    static let mist = Color(red: 0.36, green: 0.55, blue: 0.98)

    /// Vivid highlight for emphasis moments.
    static let highlight = Color(red: 0.45, green: 0.86, blue: 0.74)
}

// MARK: - Health status styling

extension CarHealthStatus {
    var tint: Color {
        switch self {
        case .overdue: .red
        case .dueSoon: .orange
        case .allClear: .green
        case .needsSetup: .blue
        }
    }

    /// A soft gradient version of the tint for glass badges and glows.
    var gradientTint: AnyGradient {
        tint.gradient
    }
}

// MARK: - Service category styling

extension ServiceCategory {
    /// A distinct, color-coded hue per category so history and charts read at a glance.
    var tint: Color {
        switch self {
        case .oil: Color(red: 0.85, green: 0.62, blue: 0.10)
        case .tires: Color(red: 0.38, green: 0.40, blue: 0.46)
        case .brakes: Color(red: 0.90, green: 0.27, blue: 0.24)
        case .engine: Color(red: 0.95, green: 0.45, blue: 0.20)
        case .transmission: Color(red: 0.55, green: 0.36, blue: 0.86)
        case .battery: Color(red: 0.30, green: 0.72, blue: 0.42)
        case .suspension: Color(red: 0.20, green: 0.62, blue: 0.78)
        case .insurance: Color(red: 0.18, green: 0.50, blue: 0.95)
        case .inspection: Color(red: 0.40, green: 0.66, blue: 0.30)
        case .other: Color(red: 0.50, green: 0.52, blue: 0.58)
        }
    }
}
