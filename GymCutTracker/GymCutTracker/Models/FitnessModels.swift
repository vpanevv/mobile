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
    var startedAt: Date
    var finishedAt: Date?
    var durationSeconds: Int
    var totalPausedSeconds: Int
    var isPaused: Bool
    var pausedAt: Date?
    var completedAt: Date?
    var bodyWeightKg: Double?
    var motivationalQuote: String?
    var notes: String
    var personalRecords: [String]
    var sessionPhotoURL: URL?
    var shareCardTemplate: ShareCardTemplate?
    var generatedShareCardURL: URL?
    var sharedAt: Date?

    init(
        id: UUID = UUID(),
        date: Date = .now,
        day: TrainingDay,
        exerciseLogs: [ExerciseLog],
        durationMinutes: Int,
        startedAt: Date? = nil,
        finishedAt: Date? = nil,
        durationSeconds: Int? = nil,
        totalPausedSeconds: Int = 0,
        isPaused: Bool = false,
        pausedAt: Date? = nil,
        completedAt: Date? = nil,
        bodyWeightKg: Double? = nil,
        motivationalQuote: String? = nil,
        notes: String = "",
        personalRecords: [String] = [],
        sessionPhotoURL: URL? = nil,
        shareCardTemplate: ShareCardTemplate? = nil,
        generatedShareCardURL: URL? = nil,
        sharedAt: Date? = nil
    ) {
        self.id = id
        self.date = date
        self.day = day
        self.exerciseLogs = exerciseLogs
        self.durationMinutes = durationMinutes
        self.startedAt = startedAt ?? date.addingTimeInterval(-TimeInterval(durationMinutes * 60))
        self.finishedAt = finishedAt
        self.durationSeconds = durationSeconds ?? max(durationMinutes * 60, 0)
        self.totalPausedSeconds = totalPausedSeconds
        self.isPaused = isPaused
        self.pausedAt = pausedAt
        self.completedAt = completedAt ?? finishedAt ?? date
        self.bodyWeightKg = bodyWeightKg
        self.motivationalQuote = motivationalQuote
        self.notes = notes
        self.personalRecords = personalRecords
        self.sessionPhotoURL = sessionPhotoURL
        self.shareCardTemplate = shareCardTemplate
        self.generatedShareCardURL = generatedShareCardURL
        self.sharedAt = sharedAt
    }

    enum CodingKeys: String, CodingKey {
        case id
        case date
        case day
        case exerciseLogs
        case durationMinutes
        case startedAt
        case finishedAt
        case durationSeconds
        case totalPausedSeconds
        case isPaused
        case pausedAt
        case completedAt
        case bodyWeightKg
        case motivationalQuote
        case notes
        case personalRecords
        case sessionPhotoURL
        case shareCardTemplate
        case generatedShareCardURL
        case sharedAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        date = try container.decode(Date.self, forKey: .date)
        day = try container.decode(TrainingDay.self, forKey: .day)
        exerciseLogs = try container.decode([ExerciseLog].self, forKey: .exerciseLogs)
        durationMinutes = try container.decode(Int.self, forKey: .durationMinutes)
        startedAt = try container.decodeIfPresent(Date.self, forKey: .startedAt) ?? date.addingTimeInterval(-TimeInterval(durationMinutes * 60))
        finishedAt = try container.decodeIfPresent(Date.self, forKey: .finishedAt)
        durationSeconds = try container.decodeIfPresent(Int.self, forKey: .durationSeconds) ?? max(durationMinutes * 60, 0)
        totalPausedSeconds = try container.decodeIfPresent(Int.self, forKey: .totalPausedSeconds) ?? 0
        isPaused = try container.decodeIfPresent(Bool.self, forKey: .isPaused) ?? false
        pausedAt = try container.decodeIfPresent(Date.self, forKey: .pausedAt)
        completedAt = try container.decodeIfPresent(Date.self, forKey: .completedAt) ?? finishedAt ?? date
        bodyWeightKg = try container.decodeIfPresent(Double.self, forKey: .bodyWeightKg)
        motivationalQuote = try container.decodeIfPresent(String.self, forKey: .motivationalQuote)
        notes = try container.decodeIfPresent(String.self, forKey: .notes) ?? ""
        personalRecords = try container.decodeIfPresent([String].self, forKey: .personalRecords) ?? []
        sessionPhotoURL = try container.decodeIfPresent(URL.self, forKey: .sessionPhotoURL)
        shareCardTemplate = try container.decodeIfPresent(ShareCardTemplate.self, forKey: .shareCardTemplate)
        generatedShareCardURL = try container.decodeIfPresent(URL.self, forKey: .generatedShareCardURL)
        sharedAt = try container.decodeIfPresent(Date.self, forKey: .sharedAt)
    }
}

enum ShareCardTemplate: String, Codable, CaseIterable, Identifiable, Hashable {
    case fullPhotoHero = "Full Photo Hero"
    case premiumStats = "Premium Stats Card"
    case minimalProgress = "Minimal Progress Card"

    var id: String { rawValue }
}

enum WorkoutMusicItemType: String, Codable, CaseIterable, Identifiable, Hashable {
    case song
    case album
    case playlist

    var id: String { rawValue }

    var title: String {
        switch self {
        case .song: "Song"
        case .album: "Album"
        case .playlist: "Playlist"
        }
    }
}

struct WorkoutMusicSelection: Identifiable, Codable, Hashable {
    var id: UUID
    var workoutDayId: TrainingDay
    var musicItemId: String
    var musicItemType: WorkoutMusicItemType
    var title: String
    var subtitle: String
    var artworkURL: URL?
    var selectedAt: Date

    init(
        id: UUID = UUID(),
        workoutDayId: TrainingDay,
        musicItemId: String,
        musicItemType: WorkoutMusicItemType,
        title: String,
        subtitle: String,
        artworkURL: URL? = nil,
        selectedAt: Date = .now
    ) {
        self.id = id
        self.workoutDayId = workoutDayId
        self.musicItemId = musicItemId
        self.musicItemType = musicItemType
        self.title = title
        self.subtitle = subtitle
        self.artworkURL = artworkURL
        self.selectedAt = selectedAt
    }
}

struct WorkoutMusicSearchResult: Identifiable, Hashable {
    var id: String
    var musicItemId: String
    var musicItemType: WorkoutMusicItemType
    var title: String
    var subtitle: String
    var artworkURL: URL?
}

struct MotivationalQuote: Identifiable, Codable, Hashable {
    let id: UUID
    let text: String

    init(id: UUID = UUID(), text: String) {
        self.id = id
        self.text = text
    }
}

enum MotivationalQuoteLibrary {
    static let fallback = "Discipline beats motivation."

    static let quotes: [MotivationalQuote] = [
        MotivationalQuote(text: "Discipline beats motivation."),
        MotivationalQuote(text: "Small wins build strong bodies."),
        MotivationalQuote(text: "You showed up. That counts."),
        MotivationalQuote(text: "Strength is built one set at a time."),
        MotivationalQuote(text: "The cut continues."),
        MotivationalQuote(text: "Earned, not given."),
        MotivationalQuote(text: "Progress is never random."),
        MotivationalQuote(text: "Keep strength while the scale moves down."),
        MotivationalQuote(text: "Another session closer."),
        MotivationalQuote(text: "Consistency creates results."),
        MotivationalQuote(text: "Your future self is watching."),
        MotivationalQuote(text: "No excuses, just reps."),
        MotivationalQuote(text: "Built by discipline."),
        MotivationalQuote(text: "The work is the reward."),
        MotivationalQuote(text: "One workout at a time."),
        MotivationalQuote(text: "Stay locked in."),
        MotivationalQuote(text: "Cut hard. Train harder."),
        MotivationalQuote(text: "The body follows the standard."),
        MotivationalQuote(text: "You did what most skip."),
        MotivationalQuote(text: "Momentum starts with action."),
        MotivationalQuote(text: "Strong mind. Strong body."),
        MotivationalQuote(text: "Today's effort becomes tomorrow's shape."),
        MotivationalQuote(text: "Reps today. Results tomorrow."),
        MotivationalQuote(text: "Quiet work. Loud results."),
        MotivationalQuote(text: "You are building proof."),
        MotivationalQuote(text: "Stay patient. Stay dangerous."),
        MotivationalQuote(text: "The session is done. The mission continues."),
        MotivationalQuote(text: "Respect the grind."),
        MotivationalQuote(text: "Fat drops. Strength stays."),
        MotivationalQuote(text: "Another brick in the physique.")
    ]

    static func randomQuote() -> MotivationalQuote {
        quotes.randomElement() ?? MotivationalQuote(text: fallback)
    }
}

extension WorkoutSession {
    var formattedDuration: String {
        formatDuration(durationSeconds)
    }

    private func formatDuration(_ seconds: Int) -> String {
        let safeSeconds = max(seconds, 0)
        let hours = safeSeconds / 3600
        let minutes = (safeSeconds % 3600) / 60
        let seconds = safeSeconds % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        }

        return String(format: "%02d:%02d", minutes, seconds)
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

enum WeightCheckInType: String, Codable, CaseIterable, Identifiable, Hashable {
    case weekly = "Weekly"
    case monthly = "Monthly"

    var id: String { rawValue }
}

struct WeightCheckIn: Identifiable, Codable, Hashable {
    var id: UUID
    var date: Date
    var weightKg: Double
    var waistCm: Double?
    var note: String?
    var type: WeightCheckInType
    var createdAt: Date

    init(
        id: UUID = UUID(),
        date: Date = .now,
        weightKg: Double,
        waistCm: Double? = nil,
        note: String? = nil,
        type: WeightCheckInType,
        createdAt: Date = .now
    ) {
        self.id = id
        self.date = date
        self.weightKg = weightKg
        self.waistCm = waistCm
        self.note = note
        self.type = type
        self.createdAt = createdAt
    }
}

struct ExercisePersonalBest: Identifiable, Codable, Hashable {
    let id: UUID
    let exerciseId: UUID
    let exerciseName: String
    let muscleGroup: String?
    let bestWeight: Double
    let bestReps: Int
    let bestSetVolume: Double
    let bestSessionVolume: Double
    let achievedAt: Date
    let workoutSessionId: UUID

    init(
        id: UUID = UUID(),
        exerciseId: UUID,
        exerciseName: String,
        muscleGroup: String?,
        bestWeight: Double,
        bestReps: Int,
        bestSetVolume: Double,
        bestSessionVolume: Double,
        achievedAt: Date,
        workoutSessionId: UUID
    ) {
        self.id = id
        self.exerciseId = exerciseId
        self.exerciseName = exerciseName
        self.muscleGroup = muscleGroup
        self.bestWeight = bestWeight
        self.bestReps = bestReps
        self.bestSetVolume = bestSetVolume
        self.bestSessionVolume = bestSessionVolume
        self.achievedAt = achievedAt
        self.workoutSessionId = workoutSessionId
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
