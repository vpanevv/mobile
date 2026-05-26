import SwiftUI
import UIKit

// MARK: - Design tokens
extension Color {
    static let neonCyan   = Color(hex: 0x22d3ee)
    static let neonViolet = Color(hex: 0xa78bfa)
    // Dark surface — used directly; light surfaces use UIColor.systemBackground
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

// MARK: - Background
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

            // Shared radial glows (opacity adjusted per scheme)
            RadialGradient(
                colors: [Color.neonCyan.opacity(scheme == .dark ? 0.13 : 0.07), .clear],
                center: UnitPoint(x: 0.5, y: 0.08),
                startRadius: 0, endRadius: 320
            )
            .ignoresSafeArea()

            RadialGradient(
                colors: [Color.neonViolet.opacity(scheme == .dark ? 0.10 : 0.06), .clear],
                center: UnitPoint(x: 0.5, y: 0.92),
                startRadius: 0, endRadius: 260
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

// MARK: - Shimmer
struct AIShimmerView: View {
    @State private var scanY: CGFloat = 0
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(
                    scheme == .dark
                        ? Color.surface.opacity(0.90)
                        : Color(UIColor.systemBackground).opacity(0.90)
                )

            GeometryReader { geo in
                Color.neonCyan.opacity(0.55)
                    .frame(height: 2)
                    .blur(radius: 3)
                    .frame(maxWidth: .infinity)
                    .offset(y: scanY * geo.size.height)
                    .onAppear {
                        withAnimation(.linear(duration: 1.1).repeatForever(autoreverses: false)) {
                            scanY = 1
                        }
                    }
            }
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))

            HStack(spacing: 8) {
                Circle().fill(Color.neonCyan).frame(width: 6, height: 6)
                Text("AI is thinking...")
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundStyle(Color.neonCyan.opacity(0.8))
            }
        }
        .frame(height: 110)
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [Color.neonCyan.opacity(0.35), Color.neonViolet.opacity(0.25)],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .shadow(color: Color.neonCyan.opacity(0.10), radius: 20)
    }
}

// MARK: - Section label
private struct SectionLabel: View {
    let text: String
    init(_ text: String) { self.text = text }

    var body: some View {
        HStack(spacing: 7) {
            RoundedRectangle(cornerRadius: 2)
                .fill(Color.neonCyan)
                .frame(width: 3, height: 11)
            Text(text)
                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                .foregroundStyle(Color.neonCyan.opacity(0.7))
                .tracking(2.5)
        }
        .padding(.horizontal, 20)
    }
}

// MARK: - Header
private struct AIHeader: View {
    var body: some View {
        VStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color.neonCyan.opacity(0.22), Color.neonViolet.opacity(0.10), .clear],
                            center: .center, startRadius: 0, endRadius: 22
                        )
                    )
                    .frame(width: 44, height: 44)

                Image(systemName: "sparkles")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color.neonCyan)
            }

            Text("WishlyAI")
                .font(.system(size: 30, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)

            Text("AI WISH GENERATOR")
                .font(.system(size: 10, weight: .semibold, design: .monospaced))
                .foregroundStyle(Color.neonCyan.opacity(0.65))
                .tracking(3.5)
        }
    }
}

// MARK: - Main view
struct ContentView: View {
    @StateObject private var viewModel = WishGeneratorViewModel()
    @EnvironmentObject var store: FavoritesStore
    @AppStorage("wishlyai.isDark") private var isDark: Bool = true
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false

    @State private var showFavorites = false
    @State private var favButtonPulse = false

    var body: some View {
        ZStack(alignment: .topTrailing) {
            NeuralBackground()

            ScrollView {
                VStack(spacing: 26) {
                    AIHeader()
                        .padding(.top, 28)

                    // Occasion
                    VStack(alignment: .leading, spacing: 10) {
                        SectionLabel("OCCASION")
                        HolidayPicker(selected: $viewModel.selectedHoliday)
                    }

                    // Language
                    VStack(alignment: .leading, spacing: 10) {
                        SectionLabel("LANGUAGE")
                        LanguagePicker(selected: $viewModel.selectedLanguage)
                    }

                    // Name
                    NameToggleField(includeName: $viewModel.includeName, name: $viewModel.name)
                        .padding(.horizontal, 20)

                    // Tone
                    ToneSlider(selectedTone: Binding(
                        get: { viewModel.selectedTone },
                        set: { viewModel.selectedTone = $0; softClearWish() }
                    ))
                    .padding(.horizontal, 20)
                    .padding(.vertical, 4)

                    // Wish Length
                    VStack(alignment: .leading, spacing: 10) {
                        SectionLabel("LENGTH")
                        LengthPicker(
                            selected: Binding(
                                get: { viewModel.selectedLength },
                                set: { viewModel.selectedLength = $0; softClearWish() }
                            )
                        )
                    }

                    // Generate
                    GenerateButton(isLoading: viewModel.isLoading) {
                        viewModel.generateWish()
                    }
                    .padding(.horizontal, 20)

                    // Loading shimmer
                    if viewModel.isLoading && viewModel.generatedWish == nil {
                        AIShimmerView()
                            .padding(.horizontal, 20)
                            .transition(.opacity.combined(with: .scale(scale: 0.96)))
                    }

                    // Result
                    if let wish = viewModel.generatedWish {
                        WishResultCard(
                            wish: wish,
                            occasion: viewModel.selectedHoliday,
                            tone: viewModel.selectedTone,
                            length: viewModel.selectedLength,
                            recipientName: viewModel.includeName ? viewModel.name : nil
                        ) {
                            viewModel.generateWish()
                        }
                        .environmentObject(store)
                        .padding(.horizontal, 20)
                        .transition(
                            .opacity
                                .combined(with: .move(edge: .bottom))
                                .combined(with: .scale(scale: 0.94))
                        )
                    }

                    Spacer(minLength: 44)
                }
            }
            .scrollDismissesKeyboard(.interactively)

            // Floating theme toggle — top-right, outside scroll
            ThemeToggleButton(isDark: $isDark)
                .padding(.top, 12)
                .padding(.trailing, 20)

            // Back + Favorites buttons — top-left
            HStack(spacing: 8) {
                // Back to onboarding
                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) {
                        hasSeenOnboarding = false
                    }
                } label: {
                    Image(systemName: "arrow.left")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Color.neonCyan)
                        .frame(width: 38, height: 38)
                        .background(
                            isDark
                                ? Color.surface.opacity(0.9)
                                : Color(UIColor.systemBackground).opacity(0.9)
                        )
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.neonCyan.opacity(0.30), lineWidth: 1))
                        .shadow(color: Color.neonCyan.opacity(0.12), radius: 8)
                }
                .buttonStyle(.plain)

                // Favorites
                Button {
                    showFavorites = true
                } label: {
                    ZStack(alignment: .topTrailing) {
                        Image(systemName: "heart.fill")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(Color(hex: 0xc084fc))
                            .frame(width: 38, height: 38)
                            .background(
                                isDark
                                    ? Color.surface.opacity(0.9)
                                    : Color(UIColor.systemBackground).opacity(0.9)
                            )
                            .clipShape(Circle())
                            .overlay(Circle().stroke(Color(hex: 0xc084fc).opacity(0.30), lineWidth: 1))
                            .shadow(color: Color(hex: 0xc084fc).opacity(0.12), radius: 8)
                            .scaleEffect(favButtonPulse ? 1.1 : 1.0)

                        if store.favorites.count > 0 {
                            Text("\(min(store.favorites.count, 99))")
                                .font(.system(size: 11, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 5)
                                .padding(.vertical, 2)
                                .background(Color.red)
                                .clipShape(Capsule())
                                .offset(x: 4, y: -4)
                        }
                    }
                }
                .buttonStyle(.plain)
                .onChange(of: store.favorites.count) { _ in
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) { favButtonPulse = true }
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7).delay(0.2)) { favButtonPulse = false }
                }
                .sheet(isPresented: $showFavorites) {
                    FavoritesView()
                        .environmentObject(store)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 12)
            .padding(.leading, 20)
        }
        .ignoresSafeArea(.keyboard)
        .preferredColorScheme(isDark ? .dark : .light)
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "Something went wrong.")
        }
        .animation(.spring(response: 0.45, dampingFraction: 0.72), value: viewModel.generatedWish != nil)
        .animation(.spring(response: 0.45, dampingFraction: 0.72), value: viewModel.isLoading)
    }

    // Fade out the result card when tone or length changes — hint that a new wish is needed
    private func softClearWish() {
        guard viewModel.generatedWish != nil else { return }
        withAnimation(.easeOut(duration: 0.25)) {
            viewModel.generatedWish = nil
        }
    }
}

#Preview {
    ContentView()
}
