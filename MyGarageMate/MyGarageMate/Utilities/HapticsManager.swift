import UIKit

enum HapticsManager {
    static func success() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    static func lightTap() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    static func warning() {
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
    }

    /// A soft, rounded impact used for selections on glass surfaces.
    static func soft() {
        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
    }

    /// A crisp, firmer impact for primary actions and confirmations.
    static func rigid() {
        UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
    }

    /// Selection tick used when moving between segments/tabs.
    static func selection() {
        UISelectionFeedbackGenerator().selectionChanged()
    }
}
