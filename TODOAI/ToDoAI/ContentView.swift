import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var store: AppStore
    @State private var hasEnteredHome = false

    var body: some View {
        ZStack {
            if hasEnteredHome {
                AppBackground()

                if let profile = store.profile {
                    DashboardView(profile: profile)
                        .transition(.asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity), removal: .opacity))
                } else {
                    SetupView()
                        .transition(.asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity), removal: .opacity))
                }
            } else {
                HomeIntroView {
                    withAnimation(.spring(response: 0.78, dampingFraction: 0.86)) {
                        hasEnteredHome = true
                    }
                }
                .transition(.opacity)
            }
        }
        .animation(.spring(response: 0.55, dampingFraction: 0.88), value: hasEnteredHome)
        .animation(.spring(response: 0.55, dampingFraction: 0.88), value: store.profile?.name ?? "")
    }
}
