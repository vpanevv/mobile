import SwiftUI

@main
struct GymCutTrackerApp: App {
    @StateObject private var store = FitnessStore()
    @StateObject private var music = AppleMusicManager.shared
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
            .environmentObject(music)
            .preferredColorScheme(.dark)
        }
    }
}
