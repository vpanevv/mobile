//import SwiftUI
//import SwiftData
//
//@main
//struct VolleyTrackerApp: App {
//    private var container: ModelContainer = {
//        let schema = Schema([
//            Coach.self,
//            AppSettings.self
//        ])
//
//        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
//
//        do {
//            return try ModelContainer(for: schema, configurations: [configuration])
//        } catch {
//            fatalError("Failed to create ModelContainer: \(error)")
//        }
//    }()
//
//    var body: some Scene {
//        WindowGroup {
//            ContentView()
//        }
//        .modelContainer(container)
//    }
//}


import SwiftUI
import SwiftData

@main
struct VolleyTrackerApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        // ✅ тук казваме кои @Model типове съществуват в базата
        .modelContainer(for: [Coach.self, AppSettings.self])
    }
}
