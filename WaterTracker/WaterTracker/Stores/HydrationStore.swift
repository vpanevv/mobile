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

    var dailySummaryTitle: String {
        totalTodayML >= dailyGoalML ? "You hit your goal" : "\(remainingML) ml left"
    }

    var dailySummarySubtitle: String {
        totalTodayML >= dailyGoalML
            ? "Nice work. You are done for today unless you want another glass."
            : "Keep going to reach your hydration target before the day ends."
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

    var sevenDayStreak: Int {
        min(currentStreak, 7)
    }

    var averageDailyIntakeLast7Days: Int {
        let totals = last7DaysSnapshots.map(\.intakeML)
        guard totals.isEmpty == false else { return 0 }
        return totals.reduce(0, +) / totals.count
    }

    var goalsHitThisWeek: Int {
        datesInCurrentWeek().reduce(0) { partialResult, date in
            partialResult + (hydration(on: date) >= dailyGoalML ? 1 : 0)
        }
    }

    var last7DaysSnapshots: [DailyHydrationSnapshot] {
        let today = calendar.startOfDay(for: .now)

        return (0..<7).compactMap { offset in
            guard let date = calendar.date(byAdding: .day, value: -(6 - offset), to: today) else {
                return nil
            }

            return DailyHydrationSnapshot(
                date: date,
                intakeML: hydration(on: date),
                goalML: dailyGoalML
            )
        }
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

    private func datesInCurrentWeek() -> [Date] {
        let today = calendar.startOfDay(for: .now)
        let weekday = calendar.component(.weekday, from: today)
        let offset = (weekday - calendar.firstWeekday + 7) % 7

        guard let weekStart = calendar.date(byAdding: .day, value: -offset, to: today) else {
            return [today]
        }

        return (0...offset).compactMap { index in
            calendar.date(byAdding: .day, value: index, to: weekStart)
        }
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

struct DailyHydrationSnapshot: Identifiable, Hashable {
    let date: Date
    let intakeML: Int
    let goalML: Int

    var id: Date { date }

    var hitGoal: Bool {
        intakeML >= goalML
    }
}
