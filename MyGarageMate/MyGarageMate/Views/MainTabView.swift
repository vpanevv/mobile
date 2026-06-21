import SwiftData
import SwiftUI

struct MainTabView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase
    let profile: UserProfile

    var body: some View {
        TabView {
            GarageView(profile: profile)
                .tabItem {
                    Label("Garage", systemImage: "car.2.fill")
                }

            UpcomingView()
                .tabItem {
                    Label("Upcoming", systemImage: "calendar.badge.clock")
                }

            SettingsView(profile: profile)
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
        }
        .task { publishSnapshot() }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active { publishSnapshot() }
        }
    }

    private func publishSnapshot() {
        GarageSnapshotWriter.update(context: modelContext, currencyCode: profile.preferredCurrencyCode)
    }
}
