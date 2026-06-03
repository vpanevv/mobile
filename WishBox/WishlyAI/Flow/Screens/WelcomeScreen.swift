import SwiftUI
import UIKit

// MARK: - WelcomeScreen

struct WelcomeScreen: View {
    @EnvironmentObject private var coordinator: WishFlowCoordinator
    @EnvironmentObject private var store:       FavoritesStore
    @AppStorage("wishlyai.isDark")   private var isDark:  Bool = true
    @StateObject private var motion = MotionManager()

    @State private var showFavorites = false
    @State private var showPeople    = false
    @State private var showLanguage  = false
    @State private var appeared      = false
    @State private var favPulse      = false
    @State private var orbPulse      = false
    @State private var iconFloat     = false
    @State private var ringRotation: Double = 0

    var body: some View {
        ZStack {
            // ── Ambient blobs (work in light + dark) ────────────────────
            WelcomeAmbientLayer(motion: motion)

            // ── Drifting sparks ──────────────────────────────────────────
            ParticleSystemView()

            // ── Content ──────────────────────────────────────────────────
            VStack(spacing: 0) {
                headerRow
                    .padding(.horizontal, 20)
                    .padding(.top, 16)

                Spacer()

                // ── Logo ─────────────────────────────────────────────────
                logoArea
                    .offset(y: iconFloat ? -8 : 0)
                    .animation(
                        .easeInOut(duration: 3.2).repeatForever(autoreverses: true),
                        value: iconFloat
                    )
                    .scaleEffect(appeared ? 1 : 0.6)
                    .opacity(appeared ? 1 : 0)
                    .animation(.spring(response: 0.65, dampingFraction: 0.68), value: appeared)

                // ── Copy ─────────────────────────────────────────────────
                VStack(spacing: 6) {
                    Text("WishlyAI")
                        .font(.system(size: 40, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)

                    Text("AI WISH GENERATOR")
                        .font(.system(size: 10, weight: .semibold, design: .monospaced))
                        .foregroundStyle(Color.neonCyan.opacity(isDark ? 0.70 : 0.55))
                        .tracking(3.5)
                }
                .padding(.top, 22)
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 14)
                .animation(.spring(response: 0.5, dampingFraction: 0.75).delay(0.12), value: appeared)

                VStack(spacing: 8) {
                    Text("Let's create a wish ✨")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)
                    Text("Beautifully personalised in 5 quick taps")
                        .font(.system(size: 15, weight: .regular, design: .rounded))
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 14)
                .multilineTextAlignment(.center)
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 14)
                .animation(.spring(response: 0.5, dampingFraction: 0.75).delay(0.20), value: appeared)

                Spacer()

                // ── CTA ──────────────────────────────────────────────────
                PrimaryFlowButton(label: "Start", icon: "sparkles") {
                    coordinator.reset()
                    coordinator.goNext(.occasion)
                }
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 20)
                .animation(.spring(response: 0.5, dampingFraction: 0.75).delay(0.32), value: appeared)
                .padding(.bottom, 52)
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                withAnimation { appeared = true }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                iconFloat = true
                orbPulse  = true
                withAnimation(.linear(duration: 18).repeatForever(autoreverses: false)) {
                    ringRotation = 360
                }
            }
        }
        .sheet(isPresented: $showFavorites) { FavoritesView().environmentObject(store) }
        .sheet(isPresented: $showPeople)    { PeopleView() }
        .sheet(isPresented: $showLanguage)  { languageSheet }
    }

    // MARK: - Logo area

    private var logoArea: some View {
        ZStack {
            // Outer glow pulse
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color(hex: 0xc084fc).opacity(orbPulse ? (isDark ? 0.28 : 0.18) : 0),
                            Color.neonCyan.opacity(orbPulse ? (isDark ? 0.14 : 0.08) : 0),
                            .clear
                        ],
                        center: .center, startRadius: 0, endRadius: 80
                    )
                )
                .frame(width: 160, height: 160)
                .blur(radius: 18)
                .animation(.easeInOut(duration: 2.4).repeatForever(autoreverses: true), value: orbPulse)

            // Rotating dashed orbit ring
            Circle()
                .stroke(
                    AngularGradient(
                        colors: [
                            Color(hex: 0xc084fc).opacity(isDark ? 0.55 : 0.35),
                            Color.neonCyan.opacity(isDark ? 0.40 : 0.25),
                            Color(hex: 0xc084fc).opacity(0.05),
                            Color(hex: 0xc084fc).opacity(isDark ? 0.55 : 0.35)
                        ],
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: 1, dash: [4, 8])
                )
                .frame(width: 108, height: 108)
                .rotationEffect(.degrees(ringRotation))

            // Orbiting dot
            Circle()
                .fill(Color(hex: 0xc084fc).opacity(isDark ? 0.9 : 0.7))
                .frame(width: 6, height: 6)
                .shadow(color: Color(hex: 0xc084fc), radius: 4)
                .offset(y: -54)
                .rotationEffect(.degrees(ringRotation))

            // Second orbiting dot (offset 180°)
            Circle()
                .fill(Color.neonCyan.opacity(isDark ? 0.8 : 0.6))
                .frame(width: 4, height: 4)
                .shadow(color: Color.neonCyan, radius: 3)
                .offset(y: 54)
                .rotationEffect(.degrees(ringRotation + 180))

            // Glass icon circle
            ZStack {
                Circle()
                    .fill(.ultraThinMaterial)
                    .overlay(
                        Circle()
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color.neonCyan.opacity(isDark ? 0.55 : 0.40),
                                        Color(hex: 0xc084fc).opacity(isDark ? 0.35 : 0.25)
                                    ],
                                    startPoint: .topLeading, endPoint: .bottomTrailing
                                ),
                                lineWidth: 1.2
                            )
                    )
                    .frame(width: 80, height: 80)
                    .shadow(color: Color(hex: 0xc084fc).opacity(isDark ? 0.35 : 0.20), radius: 20)

                Image(systemName: "gift.fill")
                    .font(.system(size: 30, weight: .semibold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.neonCyan, Color(hex: 0xc084fc)],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        )
                    )
            }

            // Small sparkle accents at corners of the orbit
            ForEach([45.0, 135.0, 225.0, 315.0], id: \.self) { angle in
                Image(systemName: "sparkle")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(Color(hex: 0xc084fc).opacity(isDark ? 0.5 : 0.35))
                    .offset(y: -70)
                    .rotationEffect(.degrees(angle + ringRotation * 0.4))
            }
        }
    }

    // MARK: - Header

    private var headerRow: some View {
        HStack(spacing: 8) {
            // Favorites
            Button { showFavorites = true } label: {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Color(hex: 0xc084fc))
                        .glassCircle()
                        .scaleEffect(favPulse ? 1.12 : 1.0)
                    if store.favorites.count > 0 {
                        Text("\(min(store.favorites.count, 99))")
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 2)
                            .background(Color.red)
                            .clipShape(Capsule())
                            .offset(x: 3, y: -3)
                    }
                }
            }
            .buttonStyle(.plain)
            .onChange(of: store.favorites.count) { _, _ in
                withAnimation(.spring(response: 0.28, dampingFraction: 0.5)) { favPulse = true }
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7).delay(0.18)) { favPulse = false }
            }

            // People
            Button {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                showPeople = true
            } label: {
                Image(systemName: "person.2.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color(hex: 0xc084fc))
                    .glassCircle()
            }
            .buttonStyle(.plain)

            // Language
            Button {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                showLanguage = true
            } label: {
                Text(coordinator.language.flag)
                    .font(.system(size: 18))
                    .glassCircle()
            }
            .buttonStyle(.plain)

            Spacer()

            ThemeToggleButton(isDark: Binding(get: { isDark }, set: { isDark = $0 }))
        }
    }

    // MARK: - Language sheet

    private var languageSheet: some View {
        VStack(spacing: 0) {
            Capsule()
                .fill(Color.primary.opacity(0.18))
                .frame(width: 36, height: 4)
                .padding(.top, 12).padding(.bottom, 20)

            Text("Language")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .padding(.bottom, 20)

            VStack(spacing: 0) {
                ForEach(WishLanguage.allCases) { lang in
                    let isSelected = coordinator.language == lang
                    Button {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        coordinator.language = lang
                        showLanguage = false
                    } label: {
                        HStack(spacing: 14) {
                            Text(lang.flag).font(.system(size: 22))
                            Text(lang.label)
                                .font(.system(size: 16, weight: isSelected ? .semibold : .regular, design: .rounded))
                                .foregroundStyle(isSelected ? Color(hex: 0xc084fc) : .primary)
                            Spacer()
                            if isSelected {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundStyle(Color(hex: 0xc084fc))
                            }
                        }
                        .padding(.horizontal, 24).padding(.vertical, 14)
                    }
                    .buttonStyle(.plain)
                    Divider().padding(.horizontal, 24)
                }
            }
            Spacer()
        }
        .presentationDetents([.medium])
        .presentationCornerRadius(28)
    }
}

// MARK: - WelcomeAmbientLayer

private struct WelcomeAmbientLayer: View {
    @ObservedObject var motion: MotionManager
    @Environment(\.colorScheme) private var scheme

    @State private var blob1Drift = false
    @State private var blob2Drift = false
    @State private var blob3Drift = false

    private var alpha: Double { scheme == .dark ? 1.0 : 0.55 }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Top-left violet blob
                Ellipse()
                    .fill(Color(hex: 0x6b21a8).opacity(0.50 * alpha))
                    .frame(width: 300, height: 220)
                    .blur(radius: 70)
                    .offset(
                        x: -geo.size.width * 0.28 + CGFloat(motion.roll * -16),
                        y: blob1Drift ? -geo.size.height * 0.24 : -geo.size.height * 0.30 + CGFloat(motion.pitch * 12)
                    )

                // Bottom-right pink blob
                Ellipse()
                    .fill(Color(hex: 0xbe185d).opacity(0.42 * alpha))
                    .frame(width: 280, height: 200)
                    .blur(radius: 75)
                    .offset(
                        x: geo.size.width * 0.25 + CGFloat(motion.roll * 14),
                        y: blob2Drift ? geo.size.height * 0.28 : geo.size.height * 0.22 + CGFloat(motion.pitch * -10)
                    )

                // Center cyan shimmer
                Ellipse()
                    .fill(Color(hex: 0x0e7490).opacity(0.28 * alpha))
                    .frame(width: 220, height: 160)
                    .blur(radius: 60)
                    .offset(
                        x: blob3Drift ? -16 : 16 + CGFloat(motion.roll * 8),
                        y: -geo.size.height * 0.05 + CGFloat(motion.pitch * 6)
                    )
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .onAppear {
            withAnimation(.easeInOut(duration: 8).repeatForever(autoreverses: true)) { blob1Drift = true }
            withAnimation(.easeInOut(duration: 11).repeatForever(autoreverses: true)) { blob2Drift = true }
            withAnimation(.easeInOut(duration: 7).repeatForever(autoreverses: true))  { blob3Drift = true }
        }
    }
}

// MARK: - View helper

private extension View {
    func glassCircle() -> some View {
        self
            .frame(width: 38, height: 38)
            .background(.ultraThinMaterial)
            .clipShape(Circle())
            .overlay(Circle().stroke(Color.primary.opacity(0.08), lineWidth: 1))
    }
}
