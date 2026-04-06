import Foundation
import Combine

@MainActor
final class HydrationStore: ObservableObject {
    @Published private(set) var entries: [HydrationEntry] = [] {
        didSet { saveEntries() }
    }

    @Published var dailyGoalML: Int = 2_000 {
        didSet { saveGoal() }
    }

    private let entriesKey = "water-tracker.entries"
    private let goalKey = "water-tracker.goal"
    private let defaults: UserDefaults
    private let calendar: Calendar

    init(defaults: UserDefaults = .standard, calendar: Calendar = .current) {
        self.defaults = defaults
        self.calendar = calendar
        load()
    }

    var todayEntries: [HydrationEntry] {
        entries
            .filter { calendar.isDateInToday($0.date) }
            .sorted { $0.date > $1.date }
    }

    var totalTodayML: Int {
        todayEntries.reduce(0) { $0 + $1.amountML }
    }

    var progress: Double {
        guard dailyGoalML > 0 else { return 0 }
        return min(Double(totalTodayML) / Double(dailyGoalML), 1.0)
    }

    var remainingML: Int {
        max(dailyGoalML - totalTodayML, 0)
    }

    var currentStreak: Int {
        var streak = 0
        var cursor = calendar.startOfDay(for: .now)

        while hydration(on: cursor) >= dailyGoalML {
            streak += 1
            guard let previousDay = calendar.date(byAdding: .day, value: -1, to: cursor) else {
                break
            }
            cursor = previousDay
        }

        return streak
    }

    func addWater(_ amountML: Int) {
        guard amountML > 0 else { return }
        entries.append(HydrationEntry(amountML: amountML))
    }

    func deleteEntries(at offsets: IndexSet) {
        let items = offsets.map { todayEntries[$0].id }
        entries.removeAll { items.contains($0.id) }
    }

    func resetToday() {
        entries.removeAll { calendar.isDateInToday($0.date) }
    }

    private func hydration(on day: Date) -> Int {
        entries
            .filter { calendar.isDate($0.date, inSameDayAs: day) }
            .reduce(0) { $0 + $1.amountML }
    }

    private func load() {
        dailyGoalML = defaults.object(forKey: goalKey) as? Int ?? 2_000

        guard let data = defaults.data(forKey: entriesKey) else { return }

        do {
            entries = try JSONDecoder().decode([HydrationEntry].self, from: data)
        } catch {
            entries = []
        }
    }

    private func saveEntries() {
        do {
            let data = try JSONEncoder().encode(entries)
            defaults.set(data, forKey: entriesKey)
        } catch {
            defaults.removeObject(forKey: entriesKey)
        }
    }

    private func saveGoal() {
        defaults.set(dailyGoalML, forKey: goalKey)
    }
}
