import SwiftUI

@main
struct ToDoAIApp: App {
    @StateObject private var store = AppStore()
    @StateObject private var subscriptions = SmartAISubscriptionStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
                .environmentObject(subscriptions)
        }
    }
}
