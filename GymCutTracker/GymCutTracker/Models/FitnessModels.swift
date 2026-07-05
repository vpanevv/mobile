import Foundation

enum TrainingDay: String, Codable, CaseIterable, Identifiable {
    case monday = "Monday"
    case wednesday = "Wednesday"
    case friday = "Friday"

    var id: String { rawValue }

    var shortTitle: String {
        switch self {
        case .monday: "Mon"
        case .wednesday: "Wed"
        case .friday: "Fri"
        }
    }

    var programTitle: String {
        switch self {
        case .monday: "Workout A"
        case .wednesday: "Workout B"
        case .friday: "Workout C"
        }
    }
}

struct WorkoutDay: Identifiable, Codable, Hashable {
    var id: TrainingDay
    var title: String
    var subtitle: String
    var exercises: [Exercise]
    var finisher: String
}

struct Exercise: Identifiable, Codable, Hashable {
    var id: UUID
    var name: String
    var muscleGroup: String
    var sets: Int
    var targetReps: String
    var restSeconds: Int
    var notes: String
    var iconName: String?

    init(
        id: UUID = UUID(),
        name: String,
        muscleGroup: String,
        sets: Int,
        targetReps: String,
        restSeconds: Int,
        notes: String = "",
        iconName: String? = nil
    ) {
        self.id = id
        self.name = name
        self.muscleGroup = muscleGroup
        self.sets = sets
        self.targetReps = targetReps
        self.restSeconds = restSeconds
        self.notes = notes
        self.iconName = iconName
    }
}

struct WorkoutSession: Identifiable, Codable, Hashable {
    var id: UUID
    var date: Date
    var day: TrainingDay
    var exerciseLogs: [ExerciseLog]
    var durationMinutes: Int
    var notes: String
    var personalRecords: [String]

    init(
        id: UUID = UUID(),
        date: Date = .now,
        day: TrainingDay,
        exerciseLogs: [ExerciseLog],
        durationMinutes: Int,
        notes: String = "",
        personalRecords: [String] = []
    ) {
        self.id = id
        self.date = date
        self.day = day
        self.exerciseLogs = exerciseLogs
        self.durationMinutes = durationMinutes
        self.notes = notes
        self.personalRecords = personalRecords
    }
}

struct ExerciseLog: Identifiable, Codable, Hashable {
    var id: UUID
    var exerciseID: UUID
    var exerciseName: String
    var muscleGroup: String
    var targetReps: String
    var setLogs: [SetLog]
    var notes: String

    init(
        id: UUID = UUID(),
        exerciseID: UUID,
        exerciseName: String,
        muscleGroup: String,
        targetReps: String,
        setLogs: [SetLog],
        notes: String = ""
    ) {
        self.id = id
        self.exerciseID = exerciseID
        self.exerciseName = exerciseName
        self.muscleGroup = muscleGroup
        self.targetReps = targetReps
        self.setLogs = setLogs
        self.notes = notes
    }
}

struct SetLog: Identifiable, Codable, Hashable {
    var id: UUID
    var setNumber: Int
    var weight: Double
    var reps: Int
    var rpe: Int
    var notes: String
    var completed: Bool

    init(
        id: UUID = UUID(),
        setNumber: Int,
        weight: Double = 0,
        reps: Int = 0,
        rpe: Int = 7,
        notes: String = "",
        completed: Bool = false
    ) {
        self.id = id
        self.setNumber = setNumber
        self.weight = weight
        self.reps = reps
        self.rpe = rpe
        self.notes = notes
        self.completed = completed
    }
}

struct BodyProgress: Identifiable, Codable, Hashable {
    var id: UUID
    var date: Date
    var weightKg: Double
    var chestCm: Double
    var waistCm: Double
    var armsCm: Double
    var legsCm: Double
    var shouldersCm: Double
    var goalWeightKg: Double
    var notes: String
    var photos: [ProgressPhoto]

    init(
        id: UUID = UUID(),
        date: Date = .now,
        weightKg: Double,
        chestCm: Double = 0,
        waistCm: Double = 0,
        armsCm: Double = 0,
        legsCm: Double = 0,
        shouldersCm: Double = 0,
        goalWeightKg: Double,
        notes: String = "",
        photos: [ProgressPhoto] = []
    ) {
        self.id = id
        self.date = date
        self.weightKg = weightKg
        self.chestCm = chestCm
        self.waistCm = waistCm
        self.armsCm = armsCm
        self.legsCm = legsCm
        self.shouldersCm = shouldersCm
        self.goalWeightKg = goalWeightKg
        self.notes = notes
        self.photos = photos
    }
}

struct ProgressPhoto: Identifiable, Codable, Hashable {
    var id: UUID
    var date: Date
    var imagePath: String
    var note: String

    init(id: UUID = UUID(), date: Date = .now, imagePath: String, note: String = "") {
        self.id = id
        self.date = date
        self.imagePath = imagePath
        self.note = note
    }
}

struct ExerciseProgress: Identifiable, Hashable {
    let exercise: Exercise
    let logs: [ExerciseLog]
    let sessions: [WorkoutSession]

    var id: UUID { exercise.id }

    var lastSetSummary: String {
        guard let set = logs.last?.setLogs.last(where: { $0.completed }) else { return "No logs yet" }
        return "\(set.weight.clean) kg x \(set.reps)"
    }

    var bestWeight: Double {
        logs.flatMap(\.setLogs).map(\.weight).max() ?? 0
    }

    var bestReps: Int {
        logs.flatMap(\.setLogs).map(\.reps).max() ?? 0
    }

    var estimatedOneRepMax: Double {
        logs.flatMap(\.setLogs).map { $0.weight * (1 + Double($0.reps) / 30) }.max() ?? 0
    }

    var volumeBySession: [(Date, Double)] {
        sessions.compactMap { session in
            guard let log = session.exerciseLogs.first(where: { $0.exerciseID == exercise.id }) else { return nil }
            let volume = log.setLogs.reduce(0) { $0 + ($1.weight * Double($1.reps)) }
            return (session.date, volume)
        }
    }

    var trend: PerformanceTrend {
        let volumes = volumeBySession.map(\.1)
        guard let last = volumes.last, volumes.count > 1 else { return logs.isEmpty ? .noData : .maintaining }
        let previous = volumes.dropLast().suffix(2)
        let baseline = previous.reduce(0, +) / Double(previous.count)
        if last > baseline * 1.03 { return .improving }
        if last < baseline * 0.97 { return .dropping }
        return .maintaining
    }
}

enum PerformanceTrend: String, Hashable {
    case improving = "Improving"
    case maintaining = "Maintaining"
    case dropping = "Dropping"
    case noData = "Needs data"
}

extension Double {
    var clean: String {
        truncatingRemainder(dividingBy: 1) == 0 ? String(format: "%.0f", self) : String(format: "%.1f", self)
    }
}
