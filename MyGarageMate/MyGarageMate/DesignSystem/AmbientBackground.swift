import SwiftUI

/// A living, softly drifting mesh-gradient backdrop.
///
/// Liquid Glass looks its best over rich, colorful content — this provides a
/// subtle, ever-shifting field of brand tones for the glass to refract, while
/// staying quiet enough to keep foreground text legible.
struct AmbientBackground: View {
    @Environment(\.colorScheme) private var colorScheme

    /// Optional tint that biases the field toward a status/category color.
    var tint: Color?

    var body: some View {
        TimelineView(.animation(minimumInterval: 1 / 30)) { context in
            let t = context.date.timeIntervalSinceReferenceDate
            let drift = Float(sin(t * 0.18))
            let drift2 = Float(cos(t * 0.13))

            let points: [SIMD2<Float>] = [
                SIMD2(0, 0), SIMD2(0.5, 0), SIMD2(1, 0),
                SIMD2(0, 0.5),
                SIMD2(0.5 + 0.12 * drift, 0.5 + 0.10 * drift2),
                SIMD2(1, 0.5),
                SIMD2(0, 1), SIMD2(0.5, 1), SIMD2(1, 1)
            ]

            MeshGradient(width: 3, height: 3, points: points, colors: meshColors)
                .ignoresSafeArea()
        }
        .background(baseColor.ignoresSafeArea())
    }

    private var baseColor: Color {
        colorScheme == .dark ? Color(white: 0.04) : Color(white: 0.97)
    }

    private var meshColors: [Color] {
        let accent = tint ?? Theme.accent
        if colorScheme == .dark {
            return [
                Color(white: 0.06), accent.opacity(0.28), Color(white: 0.05),
                Theme.mist.opacity(0.22), Color(white: 0.07), accent.opacity(0.20),
                Color(white: 0.04), Theme.ember.opacity(0.18), Color(white: 0.06)
            ]
        } else {
            return [
                Color(white: 0.99), accent.opacity(0.16), Color(white: 0.97),
                Theme.mist.opacity(0.12), Color(white: 0.99), accent.opacity(0.12),
                Color(white: 0.98), Theme.ember.opacity(0.10), Color(white: 0.99)
            ]
        }
    }
}

extension View {
    /// Places an ambient mesh backdrop behind this view.
    func ambientBackground(tint: Color? = nil) -> some View {
        background(AmbientBackground(tint: tint))
    }
}
