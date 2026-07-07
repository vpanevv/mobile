import ActivityKit
import Foundation

@MainActor
final class GymWorkoutLiveActivityManager {
    static let shared = GymWorkoutLiveActivityManager()

    private var activity: Activity<GymWorkoutActivityAttributes>?

    private init() {}

    func start(attributes: GymWorkoutActivityAttributes, state: GymWorkoutActivityAttributes.ContentState) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }

        Task {
            await endExisting()

            do {
                let content = ActivityContent(state: state, staleDate: nil)
                activity = try Activity.request(attributes: attributes, content: content, pushType: nil)
            } catch {
                activity = nil
            }
        }
    }

    func update(_ state: GymWorkoutActivityAttributes.ContentState) {
        guard let activity else { return }

        Task {
            await activity.update(ActivityContent(state: state, staleDate: nil))
        }
    }

    func end(finalState: GymWorkoutActivityAttributes.ContentState) {
        guard let activity else { return }
        self.activity = nil

        Task {
            let content = ActivityContent(state: finalState, staleDate: nil)
            await activity.end(content, dismissalPolicy: .after(.now.addingTimeInterval(20)))
        }
    }

    func cancel() {
        guard let activity else { return }
        self.activity = nil

        Task {
            await activity.end(nil, dismissalPolicy: .immediate)
        }
    }

    private func endExisting() async {
        if let activity {
            await activity.end(nil, dismissalPolicy: .immediate)
            self.activity = nil
        }
    }
}
