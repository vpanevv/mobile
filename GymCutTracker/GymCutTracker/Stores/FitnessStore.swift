import Foundation
import Combine
import SwiftUI
import UIKit

@MainActor
final class FitnessStore: ObservableObject {
    @Published var workoutDays: [WorkoutDay] = [] {
        didSet { saveWorkoutDays() }
    }

    @Published private(set) var sessions: [WorkoutSession] = [] {
        didSet { saveSessions() }
    }

    @Published private(set) var bodyEntries: [BodyProgress] = [] {
        didSet { saveBodyEntries() }
    }

    @Published private(set) var musicSelections: [WorkoutMusicSelection] = [] {
        didSet { saveMusicSelections() }
    }

    @Published private(set) var weightCheckIns: [WeightCheckIn] = [] {
        didSet { saveWeightCheckIns() }
    }

    private let workoutDaysKey = "gym-cut.workout-days"
    private let sessionsKey = "gym-cut.sessions"
    private let bodyKey = "gym-cut.body-progress"
    private let musicSelectionsKey = "gym-cut.music-selections"
    private let weightCheckInsKey = "gym-cut.weight-check-ins"
    private let defaults: UserDefaults
    private let calendar: Calendar

    init(defaults: UserDefaults = .standard, calendar: Calendar = .current) {
        self.defaults = defaults
        self.calendar = calendar
        load()
    }

    var todayTrainingDay: TrainingDay {
        switch calendar.component(.weekday, from: .now) {
        case 2: .monday
        case 4: .wednesday
        case 6: .friday
        default: nextTrainingDay
        }
    }

    var scheduledTrainingDayToday: TrainingDay? {
        trainingDay(for: .now)
    }

    var nextTrainingDay: TrainingDay {
        let weekday = calendar.component(.weekday, from: .now)
        if weekday <= 2 || weekday == 1 { return .monday }
        if weekday <= 4 { return .wednesday }
        if weekday <= 6 { return .friday }
        return .monday
    }

    var todayWorkout: WorkoutDay? {
        scheduledTrainingDayToday.map { workout(for: $0) }
    }

    var totalWorkoutsCompleted: Int {
        sessions.count
    }

    var lastWorkout: WorkoutSession? {
        sessions.sorted { $0.date > $1.date }.first
    }

    var currentBodyWeight: Double {
        sortedBodyEntries.first?.weightKg ?? 0
    }

    var goalBodyWeight: Double {
        sortedBodyEntries.first?.goalWeightKg ?? 80
    }

    var sortedBodyEntries: [BodyProgress] {
        bodyEntries.sorted { $0.date > $1.date }
    }

    var sortedWeightCheckIns: [WeightCheckIn] {
        weightCheckIns.sorted { $0.date > $1.date }
    }

    var completedWorkoutSessions: [WorkoutSession] {
        sessions.filter(isCompletedWorkout).sorted { $0.date > $1.date }
    }

    var weeklyCompletedDays: Set<TrainingDay> {
        Set(completedWorkoutSessions.filter { calendar.isDate($0.date, equalTo: .now, toGranularity: .weekOfYear) }.map(\.day))
    }

    var currentWeekActivity: ActivitySummary {
        activitySummary(for: .weekOfYear, containing: .now)
    }

    var currentMonthActivity: ActivitySummary {
        activitySummary(for: .month, containing: .now)
    }

    var strengthSummary: String {
        let improving = allExerciseProgress.filter { $0.trend == .improving }.count
        let dropping = allExerciseProgress.filter { $0.trend == .dropping }.count
        if improving > dropping { return "\(improving) lifts trending up" }
        if dropping > 0 { return "\(dropping) lifts need attention" }
        return "Strength is holding steady"
    }

    var allExerciseProgress: [ExerciseProgress] {
        workoutDays
            .flatMap(\.exercises)
            .map { exercise in
                let relatedSessions = sessions
                    .filter { session in session.exerciseLogs.contains { $0.exerciseID == exercise.id } }
                    .sorted { $0.date < $1.date }
                let logs = relatedSessions.compactMap { session in
                    session.exerciseLogs.first { $0.exerciseID == exercise.id }
                }
                return ExerciseProgress(exercise: exercise, logs: logs, sessions: relatedSessions)
            }
    }

    var exercisePersonalBests: [ExercisePersonalBest] {
        calculatePersonalBests()
    }

    func workout(for day: TrainingDay) -> WorkoutDay {
        workoutDays.first { $0.id == day } ?? Self.seedWorkouts.first { $0.id == day }!
    }

    func addExercise(to day: TrainingDay, exercise: Exercise) {
        guard let index = workoutDays.firstIndex(where: { $0.id == day }) else { return }
        workoutDays[index].exercises.append(exercise)
    }

    func updateExercise(day: TrainingDay, exercise: Exercise) {
        guard let dayIndex = workoutDays.firstIndex(where: { $0.id == day }),
              let exerciseIndex = workoutDays[dayIndex].exercises.firstIndex(where: { $0.id == exercise.id })
        else { return }
        workoutDays[dayIndex].exercises[exerciseIndex] = exercise
    }

    func deleteExercises(day: TrainingDay, offsets: IndexSet) {
        guard let index = workoutDays.firstIndex(where: { $0.id == day }) else { return }
        workoutDays[index].exercises.remove(atOffsets: offsets)
    }

    func moveExercises(day: TrainingDay, from source: IndexSet, to destination: Int) {
        guard let index = workoutDays.firstIndex(where: { $0.id == day }) else { return }
        workoutDays[index].exercises.move(fromOffsets: source, toOffset: destination)
    }

    func saveSession(_ session: WorkoutSession) {
        var completedSession = session
        completedSession.personalRecords = personalRecords(for: session)
        if completedSession.motivationalQuote == nil {
            completedSession.motivationalQuote = MotivationalQuoteLibrary.randomQuote().text
        }
        sessions.append(completedSession)
    }

    func session(id: UUID) -> WorkoutSession? {
        sessions.first { $0.id == id }
    }

    func completedSession(on date: Date) -> WorkoutSession? {
        completedWorkoutSessions.first { calendar.isDate($0.date, inSameDayAs: date) }
    }

    func updateSessionBodyWeight(_ weight: Double?, for sessionID: UUID) {
        guard let index = sessions.firstIndex(where: { $0.id == sessionID }) else { return }
        sessions[index].bodyWeightKg = weight
    }

    func attachSessionPhoto(_ image: UIImage, to sessionID: UUID) {
        guard let index = sessions.firstIndex(where: { $0.id == sessionID }),
              let url = saveImage(image, name: "session-\(sessionID.uuidString).jpg")
        else { return }
        sessions[index].sessionPhotoURL = url
        sessions[index].generatedShareCardURL = nil
    }

    func removeSessionPhoto(from sessionID: UUID) {
        guard let index = sessions.firstIndex(where: { $0.id == sessionID }) else { return }
        if let url = sessions[index].sessionPhotoURL {
            try? FileManager.default.removeItem(at: url)
        }
        sessions[index].sessionPhotoURL = nil
        sessions[index].generatedShareCardURL = nil
    }

    func updateShareCard(for sessionID: UUID, image: UIImage, template: ShareCardTemplate) -> URL? {
        guard let index = sessions.firstIndex(where: { $0.id == sessionID }),
              let url = saveImage(image, name: "share-card-\(sessionID.uuidString).png", compressionQuality: 1)
        else { return nil }
        sessions[index].shareCardTemplate = template
        sessions[index].generatedShareCardURL = url
        return url
    }

    func markSessionShared(_ sessionID: UUID) {
        guard let index = sessions.firstIndex(where: { $0.id == sessionID }) else { return }
        sessions[index].sharedAt = .now
    }

    func addBodyEntry(_ entry: BodyProgress) {
        bodyEntries.append(entry)
    }

    func addWeightCheckIn(_ checkIn: WeightCheckIn) {
        weightCheckIns.append(checkIn)
    }

    func musicSelection(for day: TrainingDay) -> WorkoutMusicSelection? {
        musicSelections.first { $0.workoutDayId == day }
    }

    func saveMusicSelection(_ selection: WorkoutMusicSelection) {
        if let index = musicSelections.firstIndex(where: { $0.workoutDayId == selection.workoutDayId }) {
            musicSelections[index] = selection
        } else {
            musicSelections.append(selection)
        }
    }

    func deleteMusicSelection(for day: TrainingDay) {
        musicSelections.removeAll { $0.workoutDayId == day }
    }

    func activitySummary(for component: Calendar.Component, containing date: Date) -> ActivitySummary {
        guard let interval = calendar.dateInterval(of: component, for: date) else {
            return ActivitySummary(startDate: date, endDate: date, scheduledCount: 0, completedCount: 0)
        }

        let scheduledDates = scheduledTrainingDates(in: interval)
        let completedDates = completedTrainingDates(in: interval)
        let completedScheduledDates = scheduledDates.filter { scheduledDate in
            completedDates.contains { calendar.isDate($0, inSameDayAs: scheduledDate) }
        }

        return ActivitySummary(
            startDate: interval.start,
            endDate: interval.end,
            scheduledCount: scheduledDates.count,
            completedCount: completedScheduledDates.count
        )
    }

    func calendarDays(forMonthContaining date: Date) -> [TrainingCalendarDay] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: date),
              let monthGrid = calendar.dateInterval(of: .weekOfMonth, for: monthInterval.start),
              let lastMonthDay = calendar.date(byAdding: .day, value: -1, to: monthInterval.end),
              let endGrid = calendar.dateInterval(of: .weekOfMonth, for: lastMonthDay)
        else { return [] }

        let completedDates = completedTrainingDates(in: DateInterval(start: monthGrid.start, end: endGrid.end))
        var days: [TrainingCalendarDay] = []
        var cursor = monthGrid.start

        while cursor < endGrid.end {
            let day = trainingDay(for: cursor)
            let completed = completedDates.contains { calendar.isDate($0, inSameDayAs: cursor) }
            days.append(
                TrainingCalendarDay(
                    date: cursor,
                    trainingDay: day,
                    completed: completed,
                    isInDisplayedMonth: calendar.isDate(cursor, equalTo: date, toGranularity: .month)
                )
            )

            guard let nextDay = calendar.date(byAdding: .day, value: 1, to: cursor) else { break }
            cursor = nextDay
        }

        return days
    }

    func weekRows(containing date: Date) -> [TrainingCalendarDay] {
        guard let interval = calendar.dateInterval(of: .weekOfYear, for: date) else { return [] }
        let completedDates = completedTrainingDates(in: interval)
        var rows: [TrainingCalendarDay] = []
        var cursor = interval.start

        while cursor < interval.end {
            if let day = trainingDay(for: cursor) {
                rows.append(
                    TrainingCalendarDay(
                        date: cursor,
                        trainingDay: day,
                        completed: completedDates.contains { calendar.isDate($0, inSameDayAs: cursor) },
                        isInDisplayedMonth: true
                    )
                )
            }
            guard let nextDay = calendar.date(byAdding: .day, value: 1, to: cursor) else { break }
            cursor = nextDay
        }

        return rows
    }

    func historyWeekSummary(containing date: Date = .now) -> HistoryWeekSummary {
        guard let interval = calendar.dateInterval(of: .weekOfYear, for: date) else {
            return HistoryWeekSummary(startDate: date, endDate: date, rows: [], completedCount: 0, targetCount: 0, status: "No week data yet")
        }

        let rows = weekRows(containing: date)
        let completedCount = rows.filter(\.completed).count
        let targetCount = rows.count
        let today = calendar.startOfDay(for: date)
        let missedScheduled = rows.contains { row in
            row.completed == false && calendar.startOfDay(for: row.date) < today
        }

        let status: String
        if targetCount > 0 && completedCount == targetCount {
            status = "Perfect week completed"
        } else if missedScheduled {
            status = "Get back on track"
        } else {
            status = "On track this week"
        }

        return HistoryWeekSummary(
            startDate: interval.start,
            endDate: calendar.date(byAdding: .day, value: -1, to: interval.end) ?? interval.end,
            rows: rows,
            completedCount: completedCount,
            targetCount: targetCount,
            status: status
        )
    }

    func historyMonthSummary(containing date: Date = .now) -> HistoryMonthSummary {
        guard let interval = calendar.dateInterval(of: .month, for: date) else {
            return HistoryMonthSummary(monthDate: date, completedCount: 0, expectedCount: 0, perfectWeeks: 0, completedWeeks: 0, missedCount: 0, consistency: 0, bestTrainingWeekCount: 0, currentTrainingStreak: 0, bestMonthlyStreak: 0)
        }

        let scheduledDates = scheduledTrainingDates(in: interval)
        let completedDates = completedTrainingDates(in: interval)
        let completedScheduledDates = scheduledDates.filter { scheduledDate in
            completedDates.contains { calendar.isDate($0, inSameDayAs: scheduledDate) }
        }

        var perfectWeeks = 0
        var completedWeeks = 0
        var bestWeekCount = 0
        var weekCursor = interval.start

        while weekCursor < interval.end {
            guard let weekInterval = calendar.dateInterval(of: .weekOfYear, for: weekCursor) else { break }
            let boundedInterval = DateInterval(start: maxDate(weekInterval.start, interval.start), end: minDate(weekInterval.end, interval.end))
            let weekScheduled = scheduledTrainingDates(in: boundedInterval)
            let weekCompleted = weekScheduled.filter { scheduledDate in
                completedDates.contains { calendar.isDate($0, inSameDayAs: scheduledDate) }
            }

            if weekCompleted.isEmpty == false {
                completedWeeks += 1
            }
            if weekScheduled.isEmpty == false && weekCompleted.count == weekScheduled.count {
                perfectWeeks += 1
            }
            bestWeekCount = max(bestWeekCount, weekCompleted.count)

            guard let nextWeek = calendar.date(byAdding: .weekOfYear, value: 1, to: weekInterval.start) else { break }
            weekCursor = nextWeek
        }

        let completedCount = completedScheduledDates.count
        let expectedCount = scheduledDates.count
        let missedCount = max(expectedCount - completedCount, 0)
        let consistency = expectedCount > 0 ? Int((Double(completedCount) / Double(expectedCount) * 100).rounded()) : 0

        return HistoryMonthSummary(
            monthDate: date,
            completedCount: completedCount,
            expectedCount: expectedCount,
            perfectWeeks: perfectWeeks,
            completedWeeks: completedWeeks,
            missedCount: missedCount,
            consistency: consistency,
            bestTrainingWeekCount: bestWeekCount,
            currentTrainingStreak: currentTrainingStreak(asOf: date),
            bestMonthlyStreak: bestTrainingStreak(in: interval)
        )
    }

    func recommendation(for log: ExerciseLog) -> String {
        let completedSets = log.setLogs.filter(\.completed)
        guard completedSets.isEmpty == false else { return "Log at least one completed set next time." }
        let target = lowerTargetReps(from: log.targetReps)
        let hitTarget = completedSets.allSatisfy { $0.reps >= target }
        let averageRPE = completedSets.reduce(0) { $0 + $1.rpe } / max(completedSets.count, 1)

        if hitTarget && averageRPE <= 8 {
            return "Increase by 2.5 kg next time."
        }
        if hitTarget {
            return "Keep the same weight and make it cleaner."
        }
        return "Target reps slipped. Keep weight or reduce 2.5 kg."
    }

    private func personalRecords(for session: WorkoutSession) -> [String] {
        session.exerciseLogs.compactMap { log in
            let currentBest = log.setLogs.map(\.weight).max() ?? 0
            let previousBest = sessions
                .flatMap(\.exerciseLogs)
                .filter { $0.exerciseID == log.exerciseID }
                .flatMap(\.setLogs)
                .map(\.weight)
                .max() ?? 0
            return currentBest > previousBest && currentBest > 0 ? "\(log.exerciseName) \(currentBest.clean) kg" : nil
        }
    }

    private func lowerTargetReps(from target: String) -> Int {
        let numbers = target
            .split { !$0.isNumber }
            .compactMap { Int($0) }
        return numbers.first ?? 1
    }

    private func scheduledTrainingDates(in interval: DateInterval) -> [Date] {
        var dates: [Date] = []
        var cursor = calendar.startOfDay(for: interval.start)

        while cursor < interval.end {
            if trainingDay(for: cursor) != nil {
                dates.append(cursor)
            }
            guard let nextDay = calendar.date(byAdding: .day, value: 1, to: cursor) else { break }
            cursor = nextDay
        }

        return dates
    }

    private func completedTrainingDates(in interval: DateInterval) -> [Date] {
        let matchingDates = completedWorkoutSessions
            .filter { interval.contains($0.date) }
            .map { calendar.startOfDay(for: $0.date) }

        return Array(Set(matchingDates)).sorted()
    }

    private func isCompletedWorkout(_ session: WorkoutSession) -> Bool {
        session.completedAt != nil &&
        session.durationSeconds > 0 &&
        session.exerciseLogs.flatMap(\.setLogs).contains { $0.completed }
    }

    private func calculatePersonalBests() -> [ExercisePersonalBest] {
        let completedSessions = completedWorkoutSessions
        let exerciseLookup = Dictionary(uniqueKeysWithValues: workoutDays.flatMap(\.exercises).map { ($0.id, $0) })
        var bestsByExercise: [UUID: ExercisePersonalBest] = [:]

        for session in completedSessions {
            for log in session.exerciseLogs {
                let completedSets = log.setLogs.filter(\.completed)
                guard completedSets.isEmpty == false else { continue }

                let bestWeightSet = completedSets.max { lhs, rhs in
                    if lhs.weight == rhs.weight { return lhs.reps < rhs.reps }
                    return lhs.weight < rhs.weight
                }
                let bestSetVolume = completedSets.map { $0.weight * Double($0.reps) }.max() ?? 0
                let sessionVolume = completedSets.reduce(0) { $0 + ($1.weight * Double($1.reps)) }
                guard let bestWeightSet else { continue }

                let candidate = ExercisePersonalBest(
                    exerciseId: log.exerciseID,
                    exerciseName: log.exerciseName,
                    muscleGroup: exerciseLookup[log.exerciseID]?.muscleGroup ?? log.muscleGroup,
                    bestWeight: bestWeightSet.weight,
                    bestReps: bestWeightSet.reps,
                    bestSetVolume: bestSetVolume,
                    bestSessionVolume: sessionVolume,
                    achievedAt: session.completedAt ?? session.date,
                    workoutSessionId: session.id
                )

                if let current = bestsByExercise[log.exerciseID] {
                    if isBetterPersonalBest(candidate, than: current) {
                        bestsByExercise[log.exerciseID] = candidate
                    }
                } else {
                    bestsByExercise[log.exerciseID] = candidate
                }
            }
        }

        return bestsByExercise.values.sorted { $0.exerciseName.localizedCaseInsensitiveCompare($1.exerciseName) == .orderedAscending }
    }

    private func isBetterPersonalBest(_ candidate: ExercisePersonalBest, than current: ExercisePersonalBest) -> Bool {
        if candidate.bestWeight != current.bestWeight { return candidate.bestWeight > current.bestWeight }
        if candidate.bestReps != current.bestReps { return candidate.bestReps > current.bestReps }
        if candidate.bestSetVolume != current.bestSetVolume { return candidate.bestSetVolume > current.bestSetVolume }
        if candidate.bestSessionVolume != current.bestSessionVolume { return candidate.bestSessionVolume > current.bestSessionVolume }
        return candidate.achievedAt > current.achievedAt
    }

    private func currentTrainingStreak(asOf date: Date) -> Int {
        guard let start = calendar.date(byAdding: .month, value: -6, to: date) else { return 0 }
        let interval = DateInterval(start: start, end: date.addingTimeInterval(1))
        let scheduledDates = scheduledTrainingDates(in: interval).filter { $0 <= calendar.startOfDay(for: date) }.reversed()
        let completedDates = completedTrainingDates(in: interval)
        var streak = 0

        for scheduledDate in scheduledDates {
            if completedDates.contains(where: { calendar.isDate($0, inSameDayAs: scheduledDate) }) {
                streak += 1
            } else {
                break
            }
        }

        return streak
    }

    private func bestTrainingStreak(in interval: DateInterval) -> Int {
        let scheduledDates = scheduledTrainingDates(in: interval)
        let completedDates = completedTrainingDates(in: interval)
        var current = 0
        var best = 0

        for scheduledDate in scheduledDates {
            if completedDates.contains(where: { calendar.isDate($0, inSameDayAs: scheduledDate) }) {
                current += 1
                best = max(best, current)
            } else {
                current = 0
            }
        }

        return best
    }

    private func minDate(_ lhs: Date, _ rhs: Date) -> Date {
        lhs < rhs ? lhs : rhs
    }

    private func maxDate(_ lhs: Date, _ rhs: Date) -> Date {
        lhs > rhs ? lhs : rhs
    }

    private func trainingDay(for date: Date) -> TrainingDay? {
        switch calendar.component(.weekday, from: date) {
        case 2: .monday
        case 4: .wednesday
        case 6: .friday
        default: nil
        }
    }

    private func load() {
        workoutDays = decode([WorkoutDay].self, key: workoutDaysKey) ?? Self.seedWorkouts
        sessions = decode([WorkoutSession].self, key: sessionsKey) ?? []
        musicSelections = decode([WorkoutMusicSelection].self, key: musicSelectionsKey) ?? []
        weightCheckIns = decode([WeightCheckIn].self, key: weightCheckInsKey) ?? []
        bodyEntries = decode([BodyProgress].self, key: bodyKey) ?? [
            BodyProgress(weightKg: 86, waistCm: 92, goalWeightKg: 80, notes: "Starting cut")
        ]
    }

    private func decode<T: Decodable>(_ type: T.Type, key: String) -> T? {
        guard let data = defaults.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }

    private func saveWorkoutDays() {
        encode(workoutDays, key: workoutDaysKey)
    }

    private func saveSessions() {
        encode(sessions, key: sessionsKey)
    }

    private func saveBodyEntries() {
        encode(bodyEntries, key: bodyKey)
    }

    private func saveMusicSelections() {
        encode(musicSelections, key: musicSelectionsKey)
    }

    private func saveWeightCheckIns() {
        encode(weightCheckIns, key: weightCheckInsKey)
    }

    private func encode<T: Encodable>(_ value: T, key: String) {
        guard let data = try? JSONEncoder().encode(value) else {
            defaults.removeObject(forKey: key)
            return
        }
        defaults.set(data, forKey: key)
    }

    private func saveImage(_ image: UIImage, name: String, compressionQuality: CGFloat = 0.88) -> URL? {
        guard let directory = sessionMediaDirectory() else { return nil }
        let url = directory.appendingPathComponent(name)
        let data: Data?

        if name.lowercased().hasSuffix(".png") {
            data = image.pngData()
        } else {
            data = image.jpegData(compressionQuality: compressionQuality)
        }

        guard let data else { return nil }

        do {
            try data.write(to: url, options: [.atomic])
            return url
        } catch {
            return nil
        }
    }

    private func sessionMediaDirectory() -> URL? {
        guard let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return nil
        }
        let directory = documents.appendingPathComponent("SessionMedia", isDirectory: true)

        if FileManager.default.fileExists(atPath: directory.path) == false {
            try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        }

        return directory
    }
}

struct ActivitySummary: Hashable {
    let startDate: Date
    let endDate: Date
    let scheduledCount: Int
    let completedCount: Int

    var percentage: Int {
        guard scheduledCount > 0 else { return 0 }
        return Int((Double(completedCount) / Double(scheduledCount) * 100).rounded())
    }

    var remainingCount: Int {
        max(scheduledCount - completedCount, 0)
    }
}

struct TrainingCalendarDay: Identifiable, Hashable {
    let date: Date
    let trainingDay: TrainingDay?
    let completed: Bool
    let isInDisplayedMonth: Bool

    var id: Date { date }
}

struct HistoryWeekSummary: Hashable {
    let startDate: Date
    let endDate: Date
    let rows: [TrainingCalendarDay]
    let completedCount: Int
    let targetCount: Int
    let status: String
}

struct HistoryMonthSummary: Hashable {
    let monthDate: Date
    let completedCount: Int
    let expectedCount: Int
    let perfectWeeks: Int
    let completedWeeks: Int
    let missedCount: Int
    let consistency: Int
    let bestTrainingWeekCount: Int
    let currentTrainingStreak: Int
    let bestMonthlyStreak: Int
}

extension FitnessStore {
    static let seedWorkouts: [WorkoutDay] = [
        WorkoutDay(
            id: .monday,
            title: "Workout A",
            subtitle: "Strength + foundation",
            exercises: [
                Exercise(name: "Barbell Squat", muscleGroup: "Legs", sets: 4, targetReps: "6-8", restSeconds: 120, iconName: "figure.strengthtraining.traditional"),
                Exercise(name: "Barbell Bench Press", muscleGroup: "Chest", sets: 4, targetReps: "6-8", restSeconds: 120, iconName: "dumbbell.fill"),
                Exercise(name: "Row (barbell or machine)", muscleGroup: "Back", sets: 4, targetReps: "8-10", restSeconds: 90, iconName: "figure.rower"),
                Exercise(name: "Shoulder Press", muscleGroup: "Shoulders", sets: 3, targetReps: "8-10", restSeconds: 90, iconName: "figure.strengthtraining.functional"),
                Exercise(name: "Romanian Deadlift", muscleGroup: "Hamstrings", sets: 3, targetReps: "10", restSeconds: 120, iconName: "figure.strengthtraining.traditional"),
                Exercise(name: "Core - Leg Raise", muscleGroup: "Core", sets: 3, targetReps: "15-20", restSeconds: 60, iconName: "figure.core.training")
            ],
            finisher: "15-20 min fast incline walk"
        ),
        WorkoutDay(
            id: .wednesday,
            title: "Workout B",
            subtitle: "Hypertrophy + calorie burn",
            exercises: [
                Exercise(name: "Leg Press", muscleGroup: "Legs", sets: 4, targetReps: "10-12", restSeconds: 90, iconName: "figure.strengthtraining.traditional"),
                Exercise(name: "Incline Dumbbell Press", muscleGroup: "Chest", sets: 4, targetReps: "10", restSeconds: 90, iconName: "dumbbell.fill"),
                Exercise(name: "Lat Pulldown / Pulley", muscleGroup: "Back", sets: 4, targetReps: "8-12", restSeconds: 90, iconName: "figure.rower"),
                Exercise(name: "Lateral Raise", muscleGroup: "Shoulders", sets: 3, targetReps: "15", restSeconds: 60, iconName: "figure.strengthtraining.functional"),
                Exercise(name: "Bulgarian Split Squat", muscleGroup: "Legs", sets: 3, targetReps: "10 each leg", restSeconds: 90, iconName: "figure.strengthtraining.traditional"),
                Exercise(name: "Biceps + Triceps Superset", muscleGroup: "Arms", sets: 3, targetReps: "12-15", restSeconds: 60, iconName: "dumbbell.fill")
            ],
            finisher: "10 min intervals: 30 sec fast / 60 sec easy"
        ),
        WorkoutDay(
            id: .friday,
            title: "Workout C",
            subtitle: "Density + definition",
            exercises: [
                Exercise(name: "Trap Bar Deadlift (or conventional)", muscleGroup: "Back / Legs", sets: 3, targetReps: "5", restSeconds: 120, iconName: "figure.strengthtraining.traditional"),
                Exercise(name: "Dips (or machine)", muscleGroup: "Chest / Triceps", sets: 3, targetReps: "10-12", restSeconds: 90, iconName: "figure.strengthtraining.functional"),
                Exercise(name: "Seated Row", muscleGroup: "Back", sets: 4, targetReps: "10-12", restSeconds: 90, iconName: "figure.rower"),
                Exercise(name: "Hip Thrust", muscleGroup: "Glutes", sets: 3, targetReps: "10", restSeconds: 90, iconName: "figure.strengthtraining.traditional"),
                Exercise(name: "Face Pull", muscleGroup: "Rear delts", sets: 3, targetReps: "15", restSeconds: 60, iconName: "figure.strengthtraining.functional"),
                Exercise(name: "Core - Cable Crunch", muscleGroup: "Core", sets: 4, targetReps: "15", restSeconds: 60, iconName: "figure.core.training")
            ],
            finisher: "20 min walk"
        )
    ]
}
