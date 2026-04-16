import SwiftUI

/// Dark AI card: near-black surface + cyan→violet gradient border + subtle glow.
struct GlassCard: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(Color.surface.opacity(0.92))
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.neonCyan.opacity(0.35),
                                Color.neonViolet.opacity(0.22),
                                Color.neonCyan.opacity(0.14)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            .shadow(color: Color.neonCyan.opacity(0.07), radius: 18, x: 0, y: 0)
    }
}

extension View {
    func glassCard() -> some View {
        modifier(GlassCard())
    }
}
