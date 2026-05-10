import SwiftUI

struct MainTabView: View {
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
    }
}
