import ActivityKit
import Foundation

struct GymWorkoutActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var currentExerciseName: String
        var currentExerciseIndex: Int
        var totalExercises: Int
        var currentSetNumber: Int
        var totalSetsForExercise: Int
        var targetWeight: Double
        var targetReps: String
        var lastSetWeight: Double
        var lastSetReps: Int
        var completedSets: Int
        var totalVolume: Double
        var workoutStartTime: Date
        var workoutDuration: TimeInterval
        var isPaused: Bool
        var isResting: Bool
        var restEndTime: Date?
        var statusText: String
        var isComplete: Bool
        var personalRecordCount: Int
    }

    var workoutSessionId: String
    var workoutDayName: String
    var workoutName: String
}
