import SwiftUI
import UIKit

// MARK: - WelcomeScreen

struct WelcomeScreen: View {
    @EnvironmentObject private var coordinator: WishFlowCoordinator
    @EnvironmentObject private var store:       FavoritesStore
    @AppStorage("wishlyai.isDark")     private var isDark:            Bool = true
    @AppStorage("hasSeenOnboarding")   private var hasSeenOnboarding: Bool = false

    @State private var showFavorites = false
    @State private var showPeople    = false
    @State private var showLanguage  = false
    @State private var appeared      = false
    @State private var favPulse      = false

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                // ── Header ──────────────────────────────────────────────────
                headerRow
                    .padding(.horizontal, 20)
                    .padding(.top, 16)

                Spacer()

                // ── Logo + copy ─────────────────────────────────────────────
                VStack(spacing: 20) {
                    // Glow + icon
                    ZStack {
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [Color.neonCyan.opacity(0.25), Color.neonViolet.opacity(0.12), .clear],
                                    center: .center, startRadius: 0, endRadius: 40
                                )
                            )
                            .frame(width: 80, height: 80)
                            .blur(radius: 6)

                        ZStack {
                            Circle()
                                .fill(.ultraThinMaterial)
                                .overlay(
                                    Circle()
                                        .stroke(
                                            LinearGradient(
                                                colors: [Color.neonCyan.opacity(0.45), Color.neonViolet.opacity(0.25)],
                                                startPoint: .topLeading, endPoint: .bottomTrailing
                                            ),
                                            lineWidth: 1
                                        )
                                )
                                .frame(width: 72, height: 72)

                            Image(systemName: "gift.fill")
                                .font(.system(size: 28, weight: .semibold))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [Color.neonCyan, Color.neonViolet],
                                        startPoint: .topLeading, endPoint: .bottomTrailing
                                    )
                                )
                        }
                    }
                    .scaleEffect(appeared ? 1 : 0.6)
                    .opacity(appeared ? 1 : 0)
                    .animation(.spring(response: 0.6, dampingFraction: 0.7), value: appeared)

                    VStack(spacing: 6) {
                        Text("WishlyAI")
                            .font(.system(size: 38, weight: .bold, design: .rounded))
                            .foregroundStyle(.primary)

                        Text("AI WISH GENERATOR")
                            .font(.system(size: 10, weight: .semibold, design: .monospaced))
                            .foregroundStyle(Color.neonCyan.opacity(0.65))
                            .tracking(3.5)
                    }
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 14)
                    .animation(.spring(response: 0.5, dampingFraction: 0.75).delay(0.10), value: appeared)

                    VStack(spacing: 8) {
                        Text("Let's create a wish ✨")
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                            .foregroundStyle(.primary)
                        Text("Beautifully personalised in 5 quick taps")
                            .font(.system(size: 15, weight: .regular, design: .rounded))
                            .foregroundStyle(.secondary)
                    }
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 14)
                    .animation(.spring(response: 0.5, dampingFraction: 0.75).delay(0.18), value: appeared)
                }
                .multilineTextAlignment(.center)

                Spacer()

                // ── CTA ─────────────────────────────────────────────────────
                PrimaryFlowButton(label: "Start", icon: "sparkles") {
                    coordinator.reset()   // fresh state on every new session
                    coordinator.goNext(.occasion)
                }
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 20)
                .animation(.spring(response: 0.5, dampingFraction: 0.75).delay(0.30), value: appeared)
                .padding(.bottom, 52)
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                withAnimation { appeared = true }
            }
        }
        // ── Sheets ──────────────────────────────────────────────────────
        .sheet(isPresented: $showFavorites) {
            FavoritesView().environmentObject(store)
        }
        .sheet(isPresented: $showPeople) {
            PeopleView()
        }
        .sheet(isPresented: $showLanguage) {
            languageSheet
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

            // Theme toggle
            ThemeToggleButton(isDark: Binding(
                get: { isDark },
                set: { isDark = $0 }
            ))
        }
    }

    // MARK: - Language sheet

    private var languageSheet: some View {
        VStack(spacing: 0) {
            Capsule()
                .fill(Color.primary.opacity(0.18))
                .frame(width: 36, height: 4)
                .padding(.top, 12)
                .padding(.bottom, 20)

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
                        .padding(.horizontal, 24)
                        .padding(.vertical, 14)
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
