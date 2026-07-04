import SwiftData
import SwiftUI

enum AppTab: Hashable {
    case today, garage, upcoming, settings
}

struct MainTabView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase
    let profile: UserProfile

    @State private var selection: AppTab = .today

    var body: some View {
        TabView(selection: $selection) {
            TodayView(profile: profile, selection: $selection)
                .tag(AppTab.today)
                .tabItem {
                    Label("Today", systemImage: "sparkles")
                }

            GarageView(profile: profile)
                .tag(AppTab.garage)
                .tabItem {
                    Label("Garage", systemImage: "car.2.fill")
                }

            UpcomingView()
                .tag(AppTab.upcoming)
                .tabItem {
                    Label("Upcoming", systemImage: "calendar.badge.clock")
                }

            SettingsView(profile: profile)
                .tag(AppTab.settings)
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
