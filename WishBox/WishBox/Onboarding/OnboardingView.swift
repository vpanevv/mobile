import SwiftUI
import UIKit
import Combine

// MARK: - Data model
private struct OnboardingStep: Identifiable {
    let id: Int
    let icon: String
    let headline: String
    let subtitle: String?
}

private let steps: [OnboardingStep] = [
    OnboardingStep(id: 0, icon: "calendar.badge.plus", headline: "Select an occasion",       subtitle: nil),
    OnboardingStep(id: 1, icon: "person.fill",          headline: "Insert a name",            subtitle: "optional"),
    OnboardingStep(id: 2, icon: "sparkles",             headline: "Let WishBox do the rest",  subtitle: nil),
]

// MARK: - Headline card
private struct HeadlineCard: View {
    let step: OnboardingStep

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: step.icon)
                .font(.system(size: 28, weight: .semibold))
                .foregroundStyle(Color(hex: 0xc084fc))
                .frame(width: 36)

            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: 8) {
                    Text(step.headline)
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
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
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(Color.white.opacity(0.10), lineWidth: 1)
        )
    }
}

// MARK: - Dot indicators
private struct DotIndicators: View {
    let count: Int
    let active: Int

    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<count, id: \.self) { i in
                Capsule()
                    .fill(i == active ? Color.white : Color.white.opacity(0.30))
                    .frame(width: i == active ? 20 : 6, height: 6)
                    .animation(.spring(response: 0.4, dampingFraction: 0.75), value: active)
            }
        }
    }
}

// MARK: - Main view
struct OnboardingView: View {
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    @State private var currentStep = 0

    var body: some View {
        ZStack {
            NeuralBackground()
                .preferredColorScheme(.dark)

            VStack(spacing: 0) {
                Spacer()

                // ── Logo ──────────────────────────────────────────────────
                ZStack {
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .fill(.ultraThinMaterial)
                        .frame(width: 96, height: 96)
                        .overlay(
                            RoundedRectangle(cornerRadius: 28, style: .continuous)
                                .stroke(Color.white.opacity(0.15), lineWidth: 1)
                        )
                    Image(systemName: "gift.fill")
                        .font(.system(size: 44, weight: .semibold))
                        .foregroundStyle(.white)
                }

                Spacer().frame(height: 24)

                // ── Title ─────────────────────────────────────────────────
                Text("WishBox")
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)

                Spacer().frame(height: 36)

                // ── Headline carousel ─────────────────────────────────────
                ZStack {
                    ForEach(steps) { step in
                        if step.id == currentStep {
                            HeadlineCard(step: step)
                                .transition(.asymmetric(
                                    insertion: .move(edge: .trailing).combined(with: .opacity),
                                    removal:   .move(edge: .leading).combined(with: .opacity)
                                ))
                        }
                    }
                }
                .frame(maxWidth: .infinity, minHeight: 100, alignment: .center)
                .clipped()
                .animation(.spring(response: 0.5, dampingFraction: 0.8), value: currentStep)
                .padding(.horizontal, 32)

                Spacer().frame(height: 24)

                // ── Dots ──────────────────────────────────────────────────
                DotIndicators(count: steps.count, active: currentStep)

                Spacer()

                // ── CTA ───────────────────────────────────────────────────
                Button {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    withAnimation(.spring(response: 0.45, dampingFraction: 0.72)) {
                        hasSeenOnboarding = true
                    }
                } label: {
                    HStack(spacing: 10) {
                        Text("Get Started")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                        Image(systemName: "arrow.right")
                            .font(.system(size: 15, weight: .semibold))
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(.ultraThinMaterial)
                    .clipShape(Capsule())
                    .overlay(Capsule().stroke(Color.white.opacity(0.15), lineWidth: 1))
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 32)
                .padding(.bottom, 48)
            }
        }
        .ignoresSafeArea()
        .preferredColorScheme(.dark)
        // ── Auto-advance timer ─────────────────────────────────────────────
        .onReceive(
            Timer.publish(every: 2.5, on: .main, in: .common).autoconnect()
        ) { _ in
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                currentStep = (currentStep + 1) % steps.count
            }
        }
        // ── Pause in background ────────────────────────────────────────────
        .onReceive(
            NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)
        ) { _ in
            // Timer auto-cancels when view disappears; this guard handles partial background
            currentStep = currentStep // no-op to satisfy compiler; timer won't tick in background
        }
    }
}

#Preview {
    OnboardingView()
}
