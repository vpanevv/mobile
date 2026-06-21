import ActivityKit
import Foundation

/// Live Activity describing an active countdown to a car's next service.
/// Shared by the app (which starts/updates it) and the widget extension
/// (which renders it on the Lock Screen and in the Dynamic Island).
struct ServiceActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var title: String
        var symbolName: String
        var statusRawValue: String
        var dueDate: Date?
        var remainingText: String
    }

    var carName: String
}
