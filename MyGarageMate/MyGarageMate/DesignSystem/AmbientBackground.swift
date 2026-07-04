import SwiftUI

/// The signature "Midnight Garage" backdrop: a near-black cinematic canvas with
/// a soft, slowly breathing accent glow and an edge vignette. Kept intentionally
/// dark so foreground content and photography feel premium and high-contrast.
struct AmbientBackground: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// Optional tint (usually a car's accent) that colours the glow.
    var tint: Color?

    private var accent: Color { tint ?? Theme.accent }

    var body: some View {
        TimelineView(.animation(minimumInterval: 1 / 20, paused: reduceMotion)) { context in
            let t = context.date.timeIntervalSinceReferenceDate
            let breathe = reduceMotion ? 0 : CGFloat(sin(t * 0.25))

            ZStack {
                Theme.canvas.ignoresSafeArea()

                // Primary accent glow, high and slightly off-centre.
                RadialGradient(
                    colors: [accent.opacity(0.30 + 0.05 * breathe), .clear],
                    center: UnitPoint(x: 0.5, y: -0.05),
                    startRadius: 0,
                    endRadius: 540 + 40 * breathe
                )
                .ignoresSafeArea()

                // Cool secondary glow low and to the side for depth.
                RadialGradient(
                    colors: [Theme.mist.opacity(0.14), .clear],
                    center: UnitPoint(x: 0.92, y: 0.9),
                    startRadius: 0,
                    endRadius: 460
                )
                .ignoresSafeArea()

                // Vignette to focus the centre and deepen the edges.
                RadialGradient(
                    colors: [.clear, .black.opacity(0.55)],
                    center: .center,
                    startRadius: 160,
                    endRadius: 720
                )
                .ignoresSafeArea()
            }
        }
    }
}

extension View {
    /// Places the cinematic backdrop behind this view.
    func ambientBackground(tint: Color? = nil) -> some View {
        background(AmbientBackground(tint: tint))
    }
}
