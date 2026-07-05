import SwiftUI

@main
struct GymCutTrackerApp: App {
    @StateObject private var store = FitnessStore()
    @AppStorage("gym-cut.has-seen-onboarding") private var hasSeenOnboarding = false

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
            .preferredColorScheme(.dark)
        }
    }
}
