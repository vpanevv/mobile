import SwiftUI
import UIKit

// MARK: - Step data

struct OnboardingStep: Identifiable {
    let id: Int
    let icon: String
    let headline: String
    let subtitle: String?
    let tint: Color
}

let onboardingSteps: [OnboardingStep] = [
    OnboardingStep(
        id: 0,
        icon: "calendar.badge.plus",
        headline: "Select an occasion",
        subtitle: nil,
        tint: Color(hex: 0x4c1d95)
    ),
    OnboardingStep(
        id: 1,
        icon: "person.fill",
        headline: "Insert a name",
        subtitle: "optional",
        tint: Color(hex: 0x1e1b4b)
    ),
    OnboardingStep(
        id: 2,
        icon: "sparkles",
        headline: "Wishly do the rest",
        subtitle: nil,
        tint: Color(hex: 0x4a044e)
    ),
]

// MARK: - Character-by-character reveal

private struct RevealText: View {
    let text: String
    let font: Font
    let color: Color
    @State private var revealed = 0

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(text.enumerated()), id: \.offset) { i, ch in
                Text(String(ch))
                    .font(font)
                    .foregroundStyle(color)
                    .opacity(i < revealed ? 1 : 0)
                    .offset(y: i < revealed ? 0 : 6)
            }
        }
        .onAppear { animateReveal() }
        .onChange(of: text) { _ in
            revealed = 0
            animateReveal()
        }
    }

    private func animateReveal() {
        for i in 0..<text.count {
            let delay = Double(i) * 0.035
            withAnimation(.spring(response: 0.35, dampingFraction: 0.7).delay(delay)) {
                revealed = i + 1
            }
        }
    }
}

// MARK: - Icon with micro-bounce

private struct BounceIcon: View {
    let systemName: String
    let tint: Color

    @State private var bounce = false

    var body: some View {
        Image(systemName: systemName)
            .font(.system(size: 28, weight: .semibold))
            .foregroundStyle(tint)
            .frame(width: 36)
            .scaleEffect(bounce ? 1.20 : 1.0)
            .onAppear {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.45)) {
                    bounce = true
                }
                withAnimation(.spring(response: 0.35, dampingFraction: 0.65).delay(0.30)) {
                    bounce = false
                }
            }
            .onChange(of: systemName) { _ in
                bounce = false
                withAnimation(.spring(response: 0.35, dampingFraction: 0.45).delay(0.05)) {
                    bounce = true
                }
                withAnimation(.spring(response: 0.35, dampingFraction: 0.65).delay(0.35)) {
                    bounce = false
                }
            }
    }
}

// MARK: - Card

struct OnboardingHeadlineCard: View {
    let step: OnboardingStep

    // Drag state passed in from parent
    @Binding var dragOffset: CGFloat
    var onSwipeLeft: () -> Void
    var onSwipeRight: () -> Void

    private let dragThreshold: CGFloat = 55

    var body: some View {
        HStack(spacing: 16) {
            BounceIcon(systemName: step.icon, tint: Color(hex: 0xc084fc))

            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: 8) {
                    RevealText(
                        text: step.headline,
                        font: .system(size: 22, weight: .bold, design: .rounded),
                        color: .primary
                    )
                    .fixedSize(horizontal: false, vertical: true)

                    if let sub = step.subtitle {
                        Text(sub)
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(Color(hex: 0xc084fc))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Color(hex: 0xc084fc).opacity(0.18))
                            .clipShape(Capsule())
                    }
                }
            }

            Spacer(minLength: 0)
        }
        .padding(20)
        .background(step.tint.opacity(0.55).blendMode(.plusLighter))
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(Color.white.opacity(0.10), lineWidth: 1)
        )
        .rotation3DEffect(
            .degrees(Double(dragOffset) / 12),
            axis: (x: 0, y: 1, z: 0),
            perspective: 0.6
        )
        .offset(x: dragOffset)
        .gesture(
            DragGesture(minimumDistance: 10)
                .onChanged { val in
                    withAnimation(.interactiveSpring()) {
                        dragOffset = val.translation.width * 0.55
                    }
                }
                .onEnded { val in
                    let v = val.predictedEndTranslation.width
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                        dragOffset = 0
                    }
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    if v < -dragThreshold { onSwipeLeft() }
                    else if v > dragThreshold { onSwipeRight() }
                }
        )
    }
}
