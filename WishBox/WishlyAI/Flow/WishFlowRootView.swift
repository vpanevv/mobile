import SwiftUI
import UIKit

// MARK: - WishFlowRootView

/// Root of the wizard flow. Holds the NavigationStack + single NeuralBackground
/// that persists across all step transitions (no flicker).
/// Each screen adds its own FlowAmbientLayer + ParticleSystemView inside its ZStack.
struct WishFlowRootView: View {
    @StateObject private var coordinator = WishFlowCoordinator()
    @EnvironmentObject private var store:  FavoritesStore
    @EnvironmentObject private var router: AppRouter
    @AppStorage("wishlyai.isDark") private var isDark: Bool = true

    init() {
        // Transparent nav bar so NeuralBackground is unbroken behind every screen
        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.shadowColor = .clear
        UINavigationBar.appearance().standardAppearance   = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        UINavigationBar.appearance().compactAppearance    = appearance
    }

    var body: some View {
        ZStack {
            // ── Persistent gradient background ───────────────────────────
            NeuralBackground()
                .ignoresSafeArea()

            NavigationStack(path: $coordinator.path) {
                WelcomeScreen()
                    .navigationDestination(for: WishFlowCoordinator.Step.self) { step in
                        switch step {
                        case .occasion:   OccasionStepView()
                        case .name:       NameStepView()
                        case .tone:       ToneStepView()
                        case .length:     LengthStepView()
                        case .generating: GeneratingStepView()
                        case .result:     ResultStepView()
                        }
                    }
            }
            .background(Color.clear)
            .tint(.white)
        }
        .preferredColorScheme(isDark ? .dark : .light)
        .environmentObject(coordinator)
        // ── Deep-link from notification ──────────────────────────────────
        .onChange(of: router.pendingWish) { _, pending in
            guard let p = pending else { return }
            coordinator.applyDeepLink(occasion: p.occasion, name: p.name)
            router.pendingWish = nil
        }
    }
}
