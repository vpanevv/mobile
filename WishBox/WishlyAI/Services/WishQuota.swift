import Foundation
import Combine

/// Tracks the free tier's daily wish allowance (resets at local midnight).
/// Pro users bypass the quota entirely — callers check `ProStore.shared.isPro` first.
@MainActor
final class WishQuota: ObservableObject {
    static let shared = WishQuota()
    static let dailyLimit = 3

    @Published private(set) var usedToday: Int = 0

    private let countKey = "wishQuota.count"
    private let dayKey   = "wishQuota.day"

    private init() { refresh() }

    var remaining: Int { max(0, Self.dailyLimit - usedToday) }
    var canGenerate: Bool { remaining > 0 }

    /// Re-reads from storage and resets the counter when the calendar day changed.
    func refresh() {
        let defaults = UserDefaults.standard
        let today = Self.dayStamp()
        if defaults.string(forKey: dayKey) != today {
            defaults.set(today, forKey: dayKey)
            defaults.set(0, forKey: countKey)
        }
        usedToday = defaults.integer(forKey: countKey)
    }

    /// Records one successful generation.
    func recordUse() {
        refresh()
        usedToday += 1
        UserDefaults.standard.set(usedToday, forKey: countKey)
    }

    private static func dayStamp() -> String {
        let comps = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        return "\(comps.year ?? 0)-\(comps.month ?? 0)-\(comps.day ?? 0)"
    }
}
