import ActivityKit
import Foundation

/// Starts, updates, and ends the Lock Screen / Dynamic Island Live Activity
/// that counts down to a car's next service.
enum ServiceActivityManager {
    static var areActivitiesEnabled: Bool {
        ActivityAuthorizationInfo().areActivitiesEnabled
    }

    static var hasActive: Bool {
        !Activity<ServiceActivityAttributes>.activities.isEmpty
    }

    @discardableResult
    static func start(
        carName: String,
        reminderTitle: String,
        symbolName: String,
        statusRawValue: String,
        dueDate: Date?
    ) -> Bool {
        guard areActivitiesEnabled else { return false }

        let attributes = ServiceActivityAttributes(carName: carName)
        let state = ServiceActivityAttributes.ContentState(
            title: reminderTitle,
            symbolName: symbolName,
            statusRawValue: statusRawValue,
            dueDate: dueDate,
            remainingText: remainingText(for: dueDate)
        )

        do {
            _ = try Activity.request(
                attributes: attributes,
                content: .init(state: state, staleDate: nil)
            )
            return true
        } catch {
            return false
        }
    }

    static func end() {
        Task {
            for activity in Activity<ServiceActivityAttributes>.activities {
                await activity.end(nil, dismissalPolicy: .immediate)
            }
        }
    }

    static func remainingText(for dueDate: Date?) -> String {
        guard let dueDate else { return "Soon" }
        let days = Calendar.current.dateComponents([.day], from: .now, to: dueDate).day ?? 0
        if days <= 0 { return "Due" }
        if days == 1 { return "1d" }
        return "\(days)d"
    }
}
