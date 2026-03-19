import SwiftUI

struct TimeMapRootView: View {
    @AppStorage("hasCompletedTimeMapOnboarding") private var hasCompletedOnboarding = false
    @StateObject private var viewModel: TimeMapViewModel

    init(container: AppContainer) {
        _viewModel = StateObject(
            wrappedValue: TimeMapViewModel(
                timeService: container.timeService,
                searchService: container.searchService,
                locationResolver: container.locationResolver,
                userLocationService: container.userLocationService
            )
        )
    }

    var body: some View {
        ZStack {
            if hasCompletedOnboarding {
                TimeMapHomeView(viewModel: viewModel)
                    .transition(.asymmetric(insertion: .opacity.combined(with: .scale(scale: 1.02)), removal: .opacity))
            } else {
                TimeMapWelcomeView {
                    withAnimation(.spring(response: 0.75, dampingFraction: 0.88)) {
                        hasCompletedOnboarding = true
                    }
                }
                .transition(.asymmetric(insertion: .opacity, removal: .move(edge: .top).combined(with: .opacity)))
            }
        }
    }
}
