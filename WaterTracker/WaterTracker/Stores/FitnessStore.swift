import Foundation
import Combine
import SwiftUI

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

    private let workoutDaysKey = "gym-cut.workout-days"
    private let sessionsKey = "gym-cut.sessions"
    private let bodyKey = "gym-cut.body-progress"
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

    var nextTrainingDay: TrainingDay {
        let weekday = calendar.component(.weekday, from: .now)
        if weekday <= 2 || weekday == 1 { return .monday }
        if weekday <= 4 { return .wednesday }
        if weekday <= 6 { return .friday }
        return .monday
    }

    var todayWorkout: WorkoutDay {
        workout(for: todayTrainingDay)
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

    var weeklyCompletedDays: Set<TrainingDay> {
        Set(sessions.filter { calendar.isDate($0.date, equalTo: .now, toGranularity: .weekOfYear) }.map(\.day))
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
        sessions.append(completedSession)
    }

    func addBodyEntry(_ entry: BodyProgress) {
        bodyEntries.append(entry)
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

    private func load() {
        workoutDays = decode([WorkoutDay].self, key: workoutDaysKey) ?? Self.seedWorkouts
        sessions = decode([WorkoutSession].self, key: sessionsKey) ?? []
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

    private func encode<T: Encodable>(_ value: T, key: String) {
        guard let data = try? JSONEncoder().encode(value) else {
            defaults.removeObject(forKey: key)
            return
        }
        defaults.set(data, forKey: key)
    }
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
