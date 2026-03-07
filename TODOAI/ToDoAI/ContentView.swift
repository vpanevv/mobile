import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var store: AppStore

    var body: some View {
        ZStack {
            AppBackground()

            if let profile = store.profile {
                DashboardView(profile: profile)
                    .transition(.opacity)
            } else {
                SetupView()
                    .transition(.opacity)
            }
        }
        .animation(.spring(response: 0.55, dampingFraction: 0.88), value: store.profile?.name ?? "")
    }
}
