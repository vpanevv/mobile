import SwiftUI
import SwiftData

@main
struct ScreenshotManagerApp: App {
    @State private var library = PhotoLibraryService()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(library)
        }
        .modelContainer(for: SavedShot.self)
    }
}
