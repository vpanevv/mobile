import UserNotifications
import Foundation

@MainActor
final class ReminderManager {
    static let shared = ReminderManager()
    private init() {}

    private let center = UNUserNotificationCenter.current()

    // Request permission lazily — only on first save, never at launch.
    func requestAuthorizationIfNeeded() async -> Bool {
        let settings = await center.notificationSettings()
        switch settings.authorizationStatus {
        case .notDetermined:
            return (try? await center.requestAuthorization(options: [.alert, .sound, .badge])) ?? false
        case .authorized, .provisional, .ephemeral:
            return true
        default:
            return false
        }
    }

    // Annual 9 AM notification on the person's day/month.
    func scheduleReminder(for person: Person) {
        var comps        = DateComponents()
        comps.day        = person.day
        comps.month      = person.month
        comps.hour       = 9
        comps.minute     = 0
        // No year → repeats every year

        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: true)

        let content       = UNMutableNotificationContent()
        content.title     = "\(person.occasion.emoji) \(occasionTitle(person))"
        content.body      = "Tap to generate a wish for \(person.name)."
        content.sound     = .default
        content.userInfo  = [
            "personID": person.id.uuidString,
            "name":     person.name,
            "occasion": person.occasionRawValue
        ]

        let request = UNNotificationRequest(
            identifier: person.notificationID,
            content: content,
            trigger: trigger
        )
        center.add(request)
    }

    func cancelReminder(for person: Person) {
        center.removePendingNotificationRequests(withIdentifiers: [person.notificationID])
    }

    private func occasionTitle(_ p: Person) -> String {
        switch p.occasion {
        case .birthday:    return "Today is \(p.name)'s birthday!"
        case .nameDay:     return "Today is \(p.name)'s name day!"
        case .anniversary: return "\(p.name)'s anniversary is today!"
        default:           return "\(p.name) has a special day today!"
        }
    }
}
