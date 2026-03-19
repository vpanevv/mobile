import Combine
import Foundation

final class TimeService {
    private lazy var timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = .autoupdatingCurrent
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        return formatter
    }()

    private lazy var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = .autoupdatingCurrent
        formatter.dateFormat = "EEEE, MMM d"
        return formatter
    }()

    func ticker() -> AnyPublisher<Date, Never> {
        Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .prepend(Date())
            .eraseToAnyPublisher()
    }

    func makeLocalTimeInfo(now: Date, placeLabel: String?) -> LocalTimeInfo {
        let timeZone = TimeZone.autoupdatingCurrent
        return LocalTimeInfo(
            currentTimeText: formattedTime(for: now, in: timeZone),
            dateText: formattedDate(for: now, in: timeZone),
            timeZoneName: readableTimeZoneName(for: timeZone),
            timeZoneIdentifier: timeZone.identifier,
            placeLabel: placeLabel ?? fallbackLocalPlaceLabel()
        )
    }

    func makeSnapshot(for location: WorldLocation, relativeTo localTimeZone: TimeZone, now: Date) -> LocationTimeSnapshot {
        let timeZone = TimeZone(identifier: location.timeZoneIdentifier) ?? .autoupdatingCurrent
        return LocationTimeSnapshot(
            id: location.id,
            location: location,
            currentTimeText: formattedTime(for: now, in: timeZone),
            dateText: formattedDate(for: now, in: timeZone),
            timeZoneName: readableTimeZoneName(for: timeZone),
            differenceText: timeDifferenceText(from: localTimeZone, to: timeZone, now: now),
            comparisonText: comparisonText(from: localTimeZone, to: timeZone, city: location.city, now: now)
        )
    }

    func formattedTime(for date: Date, in timeZone: TimeZone) -> String {
        timeFormatter.timeZone = timeZone
        return timeFormatter.string(from: date)
    }

    func formattedDate(for date: Date, in timeZone: TimeZone) -> String {
        dateFormatter.timeZone = timeZone
        return dateFormatter.string(from: date)
    }

    func readableTimeZoneName(for timeZone: TimeZone) -> String {
        timeZone.localizedName(for: .generic, locale: .autoupdatingCurrent) ?? timeZone.identifier
    }

    func timeDifferenceText(from localTimeZone: TimeZone, to remoteTimeZone: TimeZone, now: Date) -> String {
        let localOffset = localTimeZone.secondsFromGMT(for: now)
        let remoteOffset = remoteTimeZone.secondsFromGMT(for: now)
        let deltaHours = (remoteOffset - localOffset) / 3600

        switch deltaHours {
        case 0:
            return "Same time"
        case let value where value > 0:
            return "\(value) hour\(value == 1 ? "" : "s") ahead"
        default:
            let behind = abs(deltaHours)
            return "\(behind) hour\(behind == 1 ? "" : "s") behind"
        }
    }

    func comparisonText(from localTimeZone: TimeZone, to remoteTimeZone: TimeZone, city: String, now: Date) -> String {
        let yourTime = formattedTime(for: now, in: localTimeZone)
        let remoteTime = formattedTime(for: now, in: remoteTimeZone)
        return "When it is \(yourTime) for you, it is \(remoteTime) in \(city)."
    }

    private func fallbackLocalPlaceLabel() -> String {
        if let city = Locale.autoupdatingCurrent.localizedString(forRegionCode: Locale.autoupdatingCurrent.region?.identifier ?? "") {
            return city
        }

        return "Current Region"
    }
}
