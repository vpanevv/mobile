import SwiftUI
import UIKit
import Combine

// MARK: - Shimmer title

private struct ShimmerText: View {
    let text: String
    @State private var shimmerPhase: CGFloat = -1

    var body: some View {
        Text(text)
            .font(.system(size: 34, weight: .bold, design: .rounded))
            .foregroundStyle(.primary)
            .overlay(
                LinearGradient(
                    stops: [
                        .init(color: .clear,                          location: shimmerPhase - 0.18),
                        .init(color: Color(hex: 0xc084fc).opacity(0.60), location: shimmerPhase),
                        .init(color: .clear,                          location: shimmerPhase + 0.18),
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .blendMode(.plusLighter)
            )
            .onAppear { startShimmer() }
    }

    private func startShimmer() {
        shimmerPhase = -0.2
        withAnimation(.linear(duration: 0.9).delay(1.2)) {
            shimmerPhase = 1.2
        }
        // Repeat every 3 s
        Timer.scheduledTimer(withTimeInterval: 3, repeats: true) { _ in
            shimmerPhase = -0.2
            withAnimation(.linear(duration: 0.9)) {
                shimmerPhase = 1.2
            }
        }
    }
}

// MARK: - Progress bar

private struct OnboardingProgressBar: View {
    let step: Int
    let total: Int

    var progress: CGFloat { CGFloat(step + 1) / CGFloat(total) }

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.white.opacity(0.15))
                    .frame(height: 4)

                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: 0xc084fc), Color(hex: 0xf9a8d4)],
                            startPoint: .leading, endPoint: .trailing
                        )
                    )
                    .frame(width: geo.size.width * progress, height: 4)
                    .animation(.spring(response: 0.5, dampingFraction: 0.75), value: step)
            }
        }
        .frame(height: 4)
    }
}

// MARK: - Logo view

private struct OnboardingLogo: View {
    var namespace: Namespace.ID
    @State private var ringProgress: CGFloat = 0
    @State private var haloAngle: Double = 0
    @State private var pulsing = false
    @State private var burst = false

    var body: some View {
        ZStack {
            // Rotating halo
            Circle()
                .stroke(
                    AngularGradient(
                        colors: [
                            Color(hex: 0xc084fc).opacity(0.6),
                            Color(hex: 0xf9a8d4).opacity(0.3),
                            Color(hex: 0xc084fc).opacity(0.0),
                            Color(hex: 0xc084fc).opacity(0.6),
                        ],
                        center: .center,
                        angle: .degrees(haloAngle)
                    ),
                    lineWidth: 2
                )
                .frame(width: 114, height: 114)

            // Trim-path ring (entrance animation)
            Circle()
                .trim(from: 0, to: ringProgress)
                .stroke(Color(hex: 0xc084fc).opacity(0.5), lineWidth: 2)
                .frame(width: 104, height: 104)
                .rotationEffect(.degrees(-90))

            // Glass background
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(.ultraThinMaterial)
                .frame(width: 96, height: 96)
                .matchedGeometryEffect(id: "logoBackground", in: namespace)
                .overlay(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .stroke(Color.white.opacity(0.15), lineWidth: 1)
                )

            // Gift icon
            Image(systemName: "gift.fill")
                .font(.system(size: 44, weight: .semibold))
                .foregroundStyle(.primary)
                .matchedGeometryEffect(id: "logoIcon", in: namespace)
                .scaleEffect(pulsing ? 1.05 : 1.0)
        }
        .onAppear {
            // Trim ring entrance
            withAnimation(.easeOut(duration: 0.8).delay(0.1)) {
                ringProgress = 1
            }
            // Rotating halo
            withAnimation(.linear(duration: 4).repeatForever(autoreverses: false)) {
                haloAngle = 360
            }
            // Breathing pulse
            withAnimation(.easeInOut(duration: 2.2).repeatForever(autoreverses: true).delay(0.4)) {
                pulsing = true
            }
        }
        .onTapGesture {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            withAnimation(.spring(response: 0.3, dampingFraction: 0.4)) {
                burst = true
            }
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7).delay(0.25)) {
                burst = false
            }
        }
    }
}

// MARK: - Ghost preview

private struct GhostPreview: View {
    var body: some View {
        VStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.white.opacity(0.06))
                .frame(height: 44)
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.white.opacity(0.04))
                .frame(height: 44)
        }
        .padding(.horizontal, 32)
        .blur(radius: 6)
        .opacity(0.5)
        .allowsHitTesting(false)
    }
}

// MARK: - Main view

struct OnboardingView: View {
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    @AppStorage("wishly.isDark") private var isDark: Bool = true
    @StateObject private var motion = MotionManager()

    var namespace: Namespace.ID

    @State private var currentStep = 0
    @State private var seenSteps: Set<Int> = [0]
    @State private var dragOffset: CGFloat = 0
    @State private var cardVisible = true

    // Staggered entrance
    @State private var logoVisible    = false
    @State private var titleVisible   = false
    @State private var subtitleVisible = false
    @State private var cardEntrance   = false
    @State private var progressVisible = false
    @State private var buttonVisible  = false

    private let timer = Timer.publish(every: 2.8, on: .main, in: .common).autoconnect()
    private var allStepsSeen: Bool { seenSteps.count == onboardingSteps.count }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            background

            VStack(spacing: 0) {
                Spacer()
                logo
                Spacer().frame(height: 24)
                titleArea
                Spacer().frame(height: 40)
                cardArea
                Spacer().frame(height: 20)
                progressSection
                Spacer()
            }

            // Theme toggle — respects safe area naturally now
            ThemeToggleButton(isDark: $isDark)
                .padding(.top, 12)
                .padding(.trailing, 20)
        }
        // Background views carry their own .ignoresSafeArea(); the ZStack
        // intentionally respects the safe area so the toggle sits below the notch.
        .preferredColorScheme(isDark ? .dark : .light)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            ctaButton
        }
        .onAppear { runEntrance() }
        .onReceive(timer) { _ in advanceStep() }
    }

    // MARK: Sub-views

    private var background: some View {
        ZStack {
            NeuralBackground()
            AmbientBlobView(motion: motion)
            ParticleSystemView()
        }
    }

    private var logo: some View {
        OnboardingLogo(namespace: namespace)
            .opacity(logoVisible ? 1 : 0)
            .scaleEffect(logoVisible ? 1 : 0.7)
    }

    private var titleArea: some View {
        VStack(spacing: 4) {
            ShimmerText(text: "Wishly")
                .opacity(titleVisible ? 1 : 0)
                .offset(y: titleVisible ? 0 : 12)

            Text("Your AI wish generator")
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundStyle(Color(hex: 0xc084fc))
                .opacity(subtitleVisible ? 1 : 0)
                .offset(y: subtitleVisible ? 0 : 8)
        }
    }

    private var cardArea: some View {
        ZStack {
            ForEach(onboardingSteps) { step in
                if step.id == currentStep {
                    OnboardingHeadlineCard(
                        step: step,
                        dragOffset: $dragOffset,
                        onSwipeLeft: { advance(by: 1) },
                        onSwipeRight: { advance(by: -1) }
                    )
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal:   .move(edge: .leading).combined(with: .opacity)
                    ))
                    .id(step.id)
                }
            }
        }
        .frame(maxWidth: .infinity, minHeight: 100)
        .clipped()
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: currentStep)
        .padding(.horizontal, 32)
        .opacity(cardEntrance ? 1 : 0)
        .offset(y: cardEntrance ? 0 : 20)
    }

    private var progressSection: some View {
        OnboardingProgressBar(step: currentStep, total: onboardingSteps.count)
            .padding(.horizontal, 48)
            .opacity(progressVisible ? 1 : 0)
    }

    private var ctaButton: some View {
        Button {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) {
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
            .background(
                LinearGradient(
                    colors: [Color(hex: 0x7c3aed), Color(hex: 0xbe185d)],
                    startPoint: .leading, endPoint: .trailing
                )
                .opacity(allStepsSeen ? 1 : 0.35)
            )
            .clipShape(Capsule())
            .overlay(Capsule().stroke(Color.white.opacity(0.15), lineWidth: 1))
            .shadow(color: Color(hex: 0x7c3aed).opacity(allStepsSeen ? 0.45 : 0), radius: 16, y: 6)
        }
        .buttonStyle(.plain)
        .disabled(!allStepsSeen)
        .padding(.horizontal, 32)
        .padding(.bottom, 16)
        .scaleEffect(allStepsSeen ? 1 : 0.94)
        .opacity(allStepsSeen ? 1 : 0.4)
        .animation(.spring(response: 0.5, dampingFraction: 0.75), value: allStepsSeen)
    }

    // MARK: Helpers

    private func runEntrance() {
        let spring = Animation.spring(response: 0.6, dampingFraction: 0.75)
        withAnimation(spring.delay(0.0))   { logoVisible     = true }
        withAnimation(spring.delay(0.25))  { titleVisible    = true }
        withAnimation(spring.delay(0.45))  { subtitleVisible = true }
        withAnimation(spring.delay(0.65))  { cardEntrance    = true }
        withAnimation(spring.delay(0.85))  { progressVisible = true }
        withAnimation(spring.delay(1.10))  { buttonVisible   = true }
    }

    private func advance(by delta: Int) {
        let next = (currentStep + delta + onboardingSteps.count) % onboardingSteps.count
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
            currentStep = next
            seenSteps.insert(next)
        }
    }

    private func advanceStep() {
        advance(by: 1)
    }
}
