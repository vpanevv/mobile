import SwiftUI

struct TimeMapRootView: View {
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
        TimeMapHomeView(viewModel: viewModel)
    }
}
