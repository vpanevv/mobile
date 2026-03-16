import SwiftUI

@main
struct ToDoAIApp: App {
    @StateObject private var store = AppStore()
    @StateObject private var subscriptions = SmartAISubscriptionStore()
    @StateObject private var appearanceStore = AppearanceStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
                .environmentObject(subscriptions)
                .environmentObject(appearanceStore)
                .preferredColorScheme(appearanceStore.appearance.colorScheme)
        }
    }
}
