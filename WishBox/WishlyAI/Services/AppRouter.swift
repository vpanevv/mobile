import Foundation
import Combine

/// Shared router for deep-link navigation from notifications.
final class AppRouter: ObservableObject {
    static let shared = AppRouter()

    /// Set by the notification delegate when a reminder is tapped.
    /// ContentView observes this and applies it to the generator.
    @Published var pendingWish: PendingWish?

    struct PendingWish: Equatable {
        let name: String
        let occasion: HolidayType
        var tone: WishTone? = nil       // optional — used by "Regenerate" from Favorites
        var length: WishLength? = nil   // optional — used by "Regenerate" from Favorites
    }

    func apply(userInfo: [AnyHashable: Any]) {
        guard
            let name     = userInfo["name"]     as? String,
            let occRaw   = userInfo["occasion"] as? String,
            let occasion = HolidayType(rawValue: occRaw)
        else { return }

        DispatchQueue.main.async {
            self.pendingWish = PendingWish(name: name, occasion: occasion)
        }
    }
}
