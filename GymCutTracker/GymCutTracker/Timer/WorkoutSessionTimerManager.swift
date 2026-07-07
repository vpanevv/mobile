import Combine
import Foundation

@MainActor
final class WorkoutSessionTimerManager: ObservableObject {
    @Published private(set) var startedAt: Date?
    @Published private(set) var finishedAt: Date?
    @Published private(set) var totalPausedSeconds = 0
    @Published private(set) var pausedAt: Date?
    @Published private(set) var isPaused = false
    @Published private(set) var displayedDurationSeconds = 0

    private var ticker: AnyCancellable?
    private let persistenceKey = "gym-cut.active-session-timer"
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        restorePersistedState()
    }

    var activeDurationSeconds: Int {
        guard let startedAt else { return 0 }
        let endDate = pausedAt ?? finishedAt ?? .now
        return max(Int(endDate.timeIntervalSince(startedAt)) - totalPausedSeconds, 0)
    }

    var formattedTime: String {
        Self.formatDuration(activeDurationSeconds)
    }

    var statusText: String {
        if finishedAt != nil { return "Ready to finish" }
        return isPaused ? "Paused" : "Workout in progress"
    }

    func startIfNeeded(at date: Date = .now) {
        guard startedAt == nil else {
            startTicker()
            return
        }
        startedAt = date
        finishedAt = nil
        totalPausedSeconds = 0
        pausedAt = nil
        isPaused = false
        displayedDurationSeconds = 0
        persistState()
        startTicker()
    }

    func pause(at date: Date = .now) {
        guard startedAt != nil, isPaused == false else { return }
        pausedAt = date
        isPaused = true
        updateDisplayedDuration()
        persistState()
    }

    func resume(at date: Date = .now) {
        guard let pausedAt, isPaused else { return }
        totalPausedSeconds += max(Int(date.timeIntervalSince(pausedAt)), 0)
        self.pausedAt = nil
        isPaused = false
        updateDisplayedDuration()
        persistState()
    }

    func togglePause() {
        isPaused ? resume() : pause()
    }

    func stop(at date: Date = .now) -> WorkoutSessionTiming {
        if isPaused {
            resume(at: date)
        }

        let startedAt = startedAt ?? date
        finishedAt = date
        updateDisplayedDuration()
        ticker?.cancel()
        ticker = nil
        clearPersistedState()

        return WorkoutSessionTiming(
            startedAt: startedAt,
            finishedAt: date,
            durationSeconds: activeDurationSeconds,
            totalPausedSeconds: totalPausedSeconds
        )
    }

    func updateDisplayedDuration() {
        displayedDurationSeconds = activeDurationSeconds
    }

    static func formatDuration(_ seconds: Int) -> String {
        let safeSeconds = max(seconds, 0)
        let hours = safeSeconds / 3600
        let minutes = (safeSeconds % 3600) / 60
        let seconds = safeSeconds % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        }

        return String(format: "%02d:%02d", minutes, seconds)
    }

    private func startTicker() {
        guard ticker == nil else { return }
        ticker = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                Task { @MainActor in
                    self?.updateDisplayedDuration()
                }
            }
    }

    private func persistState() {
        guard let startedAt else {
            clearPersistedState()
            return
        }

        let state = PersistedTimerState(
            startedAt: startedAt,
            totalPausedSeconds: totalPausedSeconds,
            pausedAt: pausedAt,
            isPaused: isPaused
        )

        if let data = try? JSONEncoder().encode(state) {
            defaults.set(data, forKey: persistenceKey)
        }
    }

    private func restorePersistedState() {
        guard let data = defaults.data(forKey: persistenceKey),
              let state = try? JSONDecoder().decode(PersistedTimerState.self, from: data)
        else { return }

        startedAt = state.startedAt
        totalPausedSeconds = state.totalPausedSeconds
        pausedAt = state.pausedAt
        isPaused = state.isPaused
        displayedDurationSeconds = activeDurationSeconds
    }

    private func clearPersistedState() {
        defaults.removeObject(forKey: persistenceKey)
    }
}

struct WorkoutSessionTiming: Hashable {
    let startedAt: Date
    let finishedAt: Date
    let durationSeconds: Int
    let totalPausedSeconds: Int
}

private struct PersistedTimerState: Codable {
    let startedAt: Date
    let totalPausedSeconds: Int
    let pausedAt: Date?
    let isPaused: Bool
}
