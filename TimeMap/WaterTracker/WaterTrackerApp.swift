import SwiftUI

@main
struct WaterTrackerApp: App {
    @StateObject private var store = HydrationStore()
    @AppStorage("has-seen-onboarding") private var hasSeenOnboarding = false

    var body: some Scene {
        WindowGroup {
            Group {
                if hasSeenOnboarding {
                    ContentView()
                } else {
                    OnboardingView {
                        hasSeenOnboarding = true
                    }
                }
            }
            .environmentObject(store)
        }
    }
}
