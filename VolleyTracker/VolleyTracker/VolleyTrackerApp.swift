import SwiftUI
import SwiftData

@main
struct VolleyTrackerApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(for: [Coach.self, Group.self, Player.self])
    }
}
