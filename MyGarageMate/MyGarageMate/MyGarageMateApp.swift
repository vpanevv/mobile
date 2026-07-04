import SwiftData
import SwiftUI

@main
struct MyGarageMateApp: App {
    private let modelContainer = AppModelContainer.shared

    var body: some Scene {
        WindowGroup {
            AppLaunchView()
                .preferredColorScheme(.dark)
                .tint(Theme.accent)
        }
        .modelContainer(modelContainer)
    }
}
