import SwiftUI

struct FavoriteCitySnapshot {
    let favorite: FavoriteCity
    let flag: String
    let currentTimeText: String
    let dateText: String
    let timeZoneName: String
    let differenceText: String
    let offsetText: String?
    let moodTitle: String
    let moodIcon: String
    let moodTint: Color
    let gradient: LinearGradient
    let shadowColor: Color

    init(favorite: FavoriteCity, timeService: TimeService, now: Date) {
        self.favorite = favorite
        flag = FlagUtility.emoji(for: favorite.countryCode)

        let timeZone = TimeZone(identifier: favorite.timeZoneIdentifier) ?? .autoupdatingCurrent
        currentTimeText = timeService.formattedTime(for: now, in: timeZone)
        dateText = timeService.formattedDate(for: now, in: timeZone)
        timeZoneName = timeService.readableTimeZoneName(for: timeZone)
        differenceText = timeService.timeDifferenceText(from: .autoupdatingCurrent, to: timeZone, now: now)

        let hourOffset = timeZone.secondsFromGMT(for: now) - TimeZone.autoupdatingCurrent.secondsFromGMT(for: now)
        if hourOffset == 0 {
            offsetText = nil
        } else {
            let totalHours = Double(hourOffset) / 3600
            offsetText = String(format: "UTC%+.1f", totalHours)
                .replacingOccurrences(of: ".0", with: "")
        }

        let hour = Calendar.current.dateComponents(in: timeZone, from: now).hour ?? 12
        switch hour {
        case 5..<10:
            moodTitle = "Morning glow"
            moodIcon = "sunrise.fill"
            moodTint = Color(red: 1.0, green: 0.84, blue: 0.56)
            gradient = LinearGradient(
                colors: [
                    Color(red: 0.25, green: 0.44, blue: 0.92),
                    Color(red: 0.55, green: 0.79, blue: 0.98),
                    TimeMapPalette.sunrise.opacity(0.92)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            shadowColor = TimeMapPalette.electricBlue.opacity(0.30)

        case 10..<17:
            moodTitle = "Daytime now"
            moodIcon = "sun.max.fill"
            moodTint = Color(red: 1.0, green: 0.92, blue: 0.58)
            gradient = LinearGradient(
                colors: [
                    TimeMapPalette.electricBlue.opacity(0.96),
                    TimeMapPalette.cyan.opacity(0.90),
                    Color(red: 0.53, green: 0.83, blue: 0.98)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            shadowColor = TimeMapPalette.electricBlue.opacity(0.24)

        case 17..<20:
            moodTitle = "Evening light"
            moodIcon = "sun.horizon.fill"
            moodTint = Color(red: 1.0, green: 0.80, blue: 0.50)
            gradient = LinearGradient(
                colors: [
                    TimeMapPalette.indigo.opacity(0.96),
                    TimeMapPalette.violet.opacity(0.88),
                    TimeMapPalette.sunrise.opacity(0.82)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            shadowColor = TimeMapPalette.violet.opacity(0.28)

        default:
            moodTitle = "Nightfall now"
            moodIcon = "moon.stars.fill"
            moodTint = Color(red: 0.86, green: 0.91, blue: 1.0)
            gradient = LinearGradient(
                colors: [
                    TimeMapPalette.night.opacity(0.98),
                    TimeMapPalette.deepOcean.opacity(0.96),
                    TimeMapPalette.violet.opacity(0.82)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            shadowColor = TimeMapPalette.night.opacity(0.44)
        }
    }
}
