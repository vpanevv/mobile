import SwiftUI

/// Shared animation curves so motion feels consistent and intentional everywhere.
enum Motion {
    /// Standard interactive spring for taps, toggles, and selections.
    static let spring = Animation.spring(response: 0.42, dampingFraction: 0.78)

    /// A snappier spring for small, frequent UI changes.
    static let snappy = Animation.spring(response: 0.32, dampingFraction: 0.82)

    /// A slower, weightier spring for hero/large element transitions.
    static let hero = Animation.spring(response: 0.55, dampingFraction: 0.82)

    /// A gentle bounce for celebratory / delight moments.
    static let bouncy = Animation.spring(response: 0.5, dampingFraction: 0.62)

    /// Smooth fade for appearance/disappearance.
    static let fade = Animation.easeOut(duration: 0.28)
}

extension View {
    /// Applies a subtle press-scale interaction used on tappable glass surfaces.
    func pressable(_ isPressed: Bool, scale: CGFloat = 0.97) -> some View {
        scaleEffect(isPressed ? scale : 1)
            .animation(Motion.snappy, value: isPressed)
    }
}
