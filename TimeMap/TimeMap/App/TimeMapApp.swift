import SwiftUI

@main
struct TimeMapApp: App {
    private let container = AppContainer.live

    var body: some Scene {
        WindowGroup {
            TimeMapRootView(container: container)
        }
    }
}
