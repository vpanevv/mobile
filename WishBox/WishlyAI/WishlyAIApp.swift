import SwiftUI

@main
struct WishlyAIApp: App {
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    @Namespace private var logoNamespace
    @StateObject private var favoritesStore = FavoritesStore()

    var body: some Scene {
        WindowGroup {
            ZStack {
                ContentView()
                    .environmentObject(favoritesStore)

                if !hasSeenOnboarding {
                    OnboardingView(namespace: logoNamespace)
                        .transition(
                            .opacity.combined(with: .scale(scale: 1.04))
                        )
                        .zIndex(1)
                }
            }
            .animation(.spring(response: 0.5, dampingFraction: 0.85), value: hasSeenOnboarding)
        }
    }
}
