import SwiftUI
import WidgetKit

private enum FavoriteCitiesWidgetConfiguration {
    static let kind = "FavoriteCitiesWidget"
    static let appGroupID = "group.com.example.TimeMap.shared"
    static let storageKey = "timemap.favoriteCities"
}

struct FavoriteCitiesWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(
            kind: FavoriteCitiesWidgetConfiguration.kind,
            provider: FavoriteCitiesTimelineProvider()
        ) { entry in
            FavoriteCitiesWidgetView(entry: entry)
        }
        .configurationDisplayName("Favorite Cities")
        .description("Check three saved cities at a glance.")
        .supportedFamilies([.systemMedium])
        .contentMarginsDisabled()
    }
}

private struct FavoriteCitiesTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> FavoriteCitiesEntry {
        FavoriteCitiesEntry(
            date: .now,
            cities: WidgetFavoriteCity.sampleCities
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (FavoriteCitiesEntry) -> Void) {
        completion(
            FavoriteCitiesEntry(
                date: .now,
                cities: loadFavorites()
            )
        )
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<FavoriteCitiesEntry>) -> Void) {
        let entry = FavoriteCitiesEntry(
            date: .now,
            cities: loadFavorites()
        )
        let refreshDate = Calendar.current.date(byAdding: .minute, value: 15, to: .now) ?? .now.addingTimeInterval(900)
        completion(Timeline(entries: [entry], policy: .after(refreshDate)))
    }

    private func loadFavorites() -> [WidgetFavoriteCity] {
        guard
            let defaults = UserDefaults(suiteName: FavoriteCitiesWidgetConfiguration.appGroupID),
            let data = defaults.data(forKey: FavoriteCitiesWidgetConfiguration.storageKey),
            let favorites = try? JSONDecoder().decode([WidgetFavoriteCity].self, from: data)
        else {
            return []
        }

        return Array(favorites.prefix(3))
    }
}

private struct FavoriteCitiesEntry: TimelineEntry {
    let date: Date
    let cities: [WidgetFavoriteCity]
}

private struct FavoriteCitiesWidgetView: View {
    let entry: FavoriteCitiesEntry

    var body: some View {
        ZStack {
            widgetBackground

            if entry.cities.isEmpty {
                emptyState
            } else {
                VStack(alignment: .leading, spacing: 14) {
                    header

                    VStack(spacing: 10) {
                        ForEach(entry.cities) { city in
                            FavoriteCitiesWidgetRow(city: city, now: entry.date)
                        }
                    }

                    if entry.cities.count < 3 {
                        Text("Save more cities in TimeMap to fill this widget.")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(Color.white.opacity(0.56))
                            .lineLimit(1)
                    }
                }
                .padding(18)
            }
        }
        .containerBackground(for: .widget) {
            widgetBackground
        }
    }

    private var header: some View {
        HStack {
            Label("Favorites", systemImage: "heart.fill")
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(Color.white.opacity(0.92))

            Spacer(minLength: 8)

            Text("TimeMap")
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundStyle(Color.white.opacity(0.66))
        }
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("Favorites", systemImage: "heart.fill")
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(Color.white.opacity(0.92))

            Spacer(minLength: 0)

            VStack(alignment: .leading, spacing: 8) {
                Text("No saved cities yet")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)

                Text("Favorite cities in TimeMap to see three of them here.")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Color.white.opacity(0.62))
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(18)
    }

    private var widgetBackground: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.04, green: 0.08, blue: 0.18),
                    Color(red: 0.10, green: 0.20, blue: 0.42),
                    Color(red: 0.26, green: 0.22, blue: 0.66)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Circle()
                .fill(Color(red: 0.30, green: 0.87, blue: 0.96).opacity(0.22))
                .frame(width: 180, height: 180)
                .blur(radius: 40)
                .offset(x: 90, y: -80)

            Circle()
                .fill(Color(red: 1.0, green: 0.67, blue: 0.43).opacity(0.14))
                .frame(width: 140, height: 140)
                .blur(radius: 40)
                .offset(x: -90, y: 80)

            RoundedRectangle(cornerRadius: 0, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color.white.opacity(0.14), Color.clear, Color.black.opacity(0.12)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        }
    }
}

private struct FavoriteCitiesWidgetRow: View {
    let city: WidgetFavoriteCity
    let now: Date

    var body: some View {
        let snapshot = WidgetFavoriteSnapshot(city: city, now: now)

        HStack(spacing: 12) {
            Text(snapshot.flag)
                .font(.system(size: 18))
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(snapshot.city.city)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                    .lineLimit(1)

                Text(snapshot.city.country)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Color.white.opacity(0.58))
                    .lineLimit(1)
            }

            Spacer(minLength: 8)

            VStack(alignment: .trailing, spacing: 3) {
                Text(snapshot.timeText)
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(.white)
                    .lineLimit(1)

                Label(snapshot.moodTitle, systemImage: snapshot.moodIcon)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(snapshot.moodTint)
                    .labelStyle(.titleAndIcon)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.white.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.10), lineWidth: 1)
                )
        )
    }
}

private struct WidgetFavoriteCity: Identifiable, Codable {
    let id: String
    let city: String
    let country: String
    let countryCode: String?
    let timeZoneIdentifier: String
    let latitude: Double?
    let longitude: Double?

    static let sampleCities: [WidgetFavoriteCity] = [
        .init(id: "new-york", city: "New York", country: "United States", countryCode: "US", timeZoneIdentifier: "America/New_York", latitude: nil, longitude: nil),
        .init(id: "london", city: "London", country: "United Kingdom", countryCode: "GB", timeZoneIdentifier: "Europe/London", latitude: nil, longitude: nil),
        .init(id: "tokyo", city: "Tokyo", country: "Japan", countryCode: "JP", timeZoneIdentifier: "Asia/Tokyo", latitude: nil, longitude: nil)
    ]
}

private struct WidgetFavoriteSnapshot {
    let city: WidgetFavoriteCity
    let flag: String
    let timeText: String
    let moodTitle: String
    let moodIcon: String
    let moodTint: Color

    init(city: WidgetFavoriteCity, now: Date) {
        self.city = city
        flag = WidgetFlagUtility.emoji(for: city.countryCode)

        let timeZone = TimeZone(identifier: city.timeZoneIdentifier) ?? .autoupdatingCurrent
        let formatter = DateFormatter()
        formatter.locale = .autoupdatingCurrent
        formatter.timeZone = timeZone
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        timeText = formatter.string(from: now)

        let hour = Calendar.current.dateComponents(in: timeZone, from: now).hour ?? 12
        switch hour {
        case 5..<10:
            moodTitle = "Morning"
            moodIcon = "sunrise.fill"
            moodTint = Color(red: 1.0, green: 0.84, blue: 0.56)
        case 10..<17:
            moodTitle = "Day"
            moodIcon = "sun.max.fill"
            moodTint = Color(red: 1.0, green: 0.92, blue: 0.58)
        case 17..<20:
            moodTitle = "Evening"
            moodIcon = "sun.horizon.fill"
            moodTint = Color(red: 1.0, green: 0.80, blue: 0.50)
        default:
            moodTitle = "Night"
            moodIcon = "moon.stars.fill"
            moodTint = Color(red: 0.86, green: 0.91, blue: 1.0)
        }
    }
}

private enum WidgetFlagUtility {
    static func emoji(for countryCode: String?) -> String {
        guard let countryCode, countryCode.count == 2 else {
            return "🌍"
        }

        let base: UInt32 = 127_397
        return countryCode.uppercased().unicodeScalars.compactMap { scalar in
            UnicodeScalar(base + scalar.value)
        }
        .map(String.init)
        .joined()
    }
}
