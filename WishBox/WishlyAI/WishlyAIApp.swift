import SwiftUI
import SwiftData
import UserNotifications

@main
struct WishlyAIApp: App {
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    @Namespace private var logoNamespace
    @StateObject private var favoritesStore = FavoritesStore()
    @StateObject private var router         = AppRouter.shared

    @UIApplicationDelegateAdaptor private var appDelegate: AppDelegate

    var body: some Scene {
        WindowGroup {
            ZStack {
                ContentView()
                    .environmentObject(favoritesStore)
                    .environmentObject(router)

                if !hasSeenOnboarding {
                    OnboardingView(namespace: logoNamespace)
                        .transition(
                            .opacity.combined(with: .scale(scale: 1.04))
                        )
                        .zIndex(1)
                }
            }
            .animation(.spring(response: 0.5, dampingFraction: 0.85), value: hasSeenOnboarding)
        }
        .modelContainer(for: Person.self)
    }
}

// MARK: - App Delegate (notification delegate + cold-launch deep link)

final class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        return true
    }

    // Foreground delivery — show as banner while app is open
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler handler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        handler([.banner, .sound])
    }

    // User tapped notification — deep link into generator
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler handler: @escaping () -> Void
    ) {
        let info = response.notification.request.content.userInfo
        AppRouter.shared.apply(userInfo: info)
        handler()
    }
}
