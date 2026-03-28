import Foundation

struct ConnectionRecommendation: Equatable {
    let title: String
    let timeText: String
    let detailText: String
}

enum ConnectionRecommendationService {
    static func makeRecommendation(
        for location: WorldLocation,
        relativeTo localTimeZone: TimeZone = .autoupdatingCurrent,
        now: Date = .now
    ) -> ConnectionRecommendation {
        let remoteTimeZone = TimeZone(identifier: location.timeZoneIdentifier) ?? .autoupdatingCurrent
        var remoteCalendar = Calendar(identifier: .gregorian)
        remoteCalendar.timeZone = remoteTimeZone

        var localCalendar = Calendar(identifier: .gregorian)
        localCalendar.timeZone = localTimeZone

        let remoteBaseDate = remoteCalendar.startOfDay(for: now)
        let preferredStartToday = remoteCalendar.date(bySettingHour: 13, minute: 0, second: 0, of: remoteBaseDate) ?? now
        let preferredEndToday = remoteCalendar.date(bySettingHour: 15, minute: 0, second: 0, of: remoteBaseDate) ?? now

        let useTomorrow = preferredEndToday <= now
        let startDate = useTomorrow ? remoteCalendar.date(byAdding: .day, value: 1, to: preferredStartToday) ?? preferredStartToday : preferredStartToday
        let endDate = useTomorrow ? remoteCalendar.date(byAdding: .day, value: 1, to: preferredEndToday) ?? preferredEndToday : preferredEndToday

        let localFormatter = DateIntervalFormatter()
        localFormatter.locale = .autoupdatingCurrent
        localFormatter.timeZone = localTimeZone
        localFormatter.dateStyle = .none
        localFormatter.timeStyle = .short

        let timeText = localFormatter.string(from: startDate, to: endDate)

        let remoteFormatter = DateIntervalFormatter()
        remoteFormatter.locale = .autoupdatingCurrent
        remoteFormatter.timeZone = remoteTimeZone
        remoteFormatter.dateStyle = .none
        remoteFormatter.timeStyle = .short

        let remoteWindowText = remoteFormatter.string(from: startDate, to: endDate)
        let title = useTomorrow ? "Best time to connect tomorrow" : "Best time to connect today"
        let detailText = "Targets \(remoteWindowText) in \(location.city)."

        return ConnectionRecommendation(
            title: title,
            timeText: "\(timeText) your time",
            detailText: detailText
        )
    }
}
