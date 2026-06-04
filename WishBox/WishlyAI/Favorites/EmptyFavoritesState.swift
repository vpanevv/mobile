import SwiftUI
import UIKit

struct EmptyFavoritesState: View {
    var onCreateWish: () -> Void

    @State private var pulse = false
    @State private var shimmerPhase: CGFloat = -1

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            Image(systemName: "heart.slash")
                .font(.system(size: 72, weight: .light))
                .foregroundStyle(Color(hex: 0xc084fc).opacity(0.55))
                .scaleEffect(pulse ? 1.05 : 1.0)
                .animation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true), value: pulse)

            Text("No favorites yet")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)
                .padding(.top, 16)

            Text("Tap the heart on any wish to save it here for later")
                .font(.system(size: 15, weight: .regular, design: .rounded))
                .foregroundStyle(.primary.opacity(0.55))
                .multilineTextAlignment(.center)
                .frame(maxWidth: 280)
                .padding(.top, 8)

            // Ghost CTA → returns to the main flow
            Button {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                onCreateWish()
            } label: {
                HStack(spacing: 7) {
                    Text("Create a wish")
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                    Text("✨")
                }
                .foregroundStyle(.primary)
                .padding(.horizontal, 22)
                .frame(height: 44)
                .background(.ultraThinMaterial)
                .clipShape(Capsule())
                .overlay(
                    Capsule().stroke(Color.white.opacity(0.18), lineWidth: 1)
                )
                .overlay(
                    // subtle shimmer sweep
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [.clear, Color.white.opacity(0.22), .clear],
                                startPoint: .init(x: shimmerPhase, y: 0),
                                endPoint: .init(x: shimmerPhase + 0.4, y: 0)
                            )
                        )
                        .clipShape(Capsule())
                )
            }
            .buttonStyle(.plain)
            .padding(.top, 24)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 32)
        .onAppear {
            pulse = true
            withAnimation(.linear(duration: 1.8).repeatForever(autoreverses: false).delay(1.0)) {
                shimmerPhase = 1.4
            }
        }
    }
}
