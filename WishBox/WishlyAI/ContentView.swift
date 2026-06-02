import SwiftUI
import UIKit

// MARK: - Design tokens (still live here — used throughout the app)

extension Color {
    static let neonCyan   = Color(hex: 0x22d3ee)
    static let neonViolet = Color(hex: 0xa78bfa)
    static let surface    = Color(hex: 0x080d1a)

    init(hex: UInt, opacity: Double = 1.0) {
        self.init(
            .sRGB,
            red:   Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8)  & 0xFF) / 255,
            blue:  Double(hex         & 0xFF) / 255,
            opacity: opacity
        )
    }
}

// MARK: - NeuralBackground (shared across flow — rendered ONCE in WishFlowRootView)

struct NeuralBackground: View {
    @Environment(\.colorScheme) private var scheme
    @State private var phase: CGFloat = 0

    var body: some View {
        ZStack {
            if scheme == .dark {
                MeshGradient(
                    width: 3, height: 3,
                    points: [
                        [0.0, 0.0], [0.5, 0.0], [1.0, 0.0],
                        [0.0, 0.5], [phase > 0.5 ? 0.55 : 0.45, 0.38], [1.0, 0.5],
                        [0.0, 1.0], [0.5, 1.0], [1.0, 1.0]
                    ],
                    colors: [
                        Color(hex: 0x030712), Color(hex: 0x05091a), Color(hex: 0x030712),
                        Color(hex: 0x08001a), Color(hex: 0x0f0030), Color(hex: 0x050015),
                        Color(hex: 0x030712), Color(hex: 0x060a1c), Color(hex: 0x030712)
                    ]
                )
                .ignoresSafeArea()
            } else {
                MeshGradient(
                    width: 3, height: 3,
                    points: [
                        [0.0, 0.0], [0.5, 0.0], [1.0, 0.0],
                        [0.0, 0.5], [phase > 0.5 ? 0.55 : 0.45, 0.42], [1.0, 0.5],
                        [0.0, 1.0], [0.5, 1.0], [1.0, 1.0]
                    ],
                    colors: [
                        Color(hex: 0xeef2ff), Color(hex: 0xf0f4ff), Color(hex: 0xeef2ff),
                        Color(hex: 0xf3f0ff), Color(hex: 0xede9fe), Color(hex: 0xf5f3ff),
                        Color(hex: 0xeef2ff), Color(hex: 0xf0f9ff), Color(hex: 0xeef2ff)
                    ]
                )
                .ignoresSafeArea()
            }

            RadialGradient(
                colors: [Color.neonCyan.opacity(scheme == .dark ? 0.13 : 0.07), .clear],
                center: UnitPoint(x: 0.5, y: 0.08), startRadius: 0, endRadius: 320
            )
            .ignoresSafeArea()

            RadialGradient(
                colors: [Color.neonViolet.opacity(scheme == .dark ? 0.10 : 0.06), .clear],
                center: UnitPoint(x: 0.5, y: 0.92), startRadius: 0, endRadius: 260
            )
            .ignoresSafeArea()
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 9).repeatForever(autoreverses: true)) {
                phase = 1
            }
        }
    }
}

// MARK: - ContentView — thin shell, all logic lives in WishFlowRootView

struct ContentView: View {
    var body: some View {
        WishFlowRootView()
    }
}

#Preview {
    ContentView()
        .environmentObject(FavoritesStore())
        .environmentObject(AppRouter.shared)
}
