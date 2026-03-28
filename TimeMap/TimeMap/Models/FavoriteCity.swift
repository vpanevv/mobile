import CoreLocation
import Foundation

struct FavoriteCity: Identifiable, Codable, Equatable {
    let id: String
    let city: String
    let country: String
    let countryCode: String?
    let timeZoneIdentifier: String
    let latitude: Double?
    let longitude: Double?

    init(
        id: String? = nil,
        city: String,
        country: String,
        countryCode: String?,
        timeZoneIdentifier: String,
        latitude: Double?,
        longitude: Double?
    ) {
        self.city = city
        self.country = country
        self.countryCode = countryCode
        self.timeZoneIdentifier = timeZoneIdentifier
        self.latitude = latitude
        self.longitude = longitude
        self.id = id ?? FavoriteCity.makeID(
            city: city,
            country: country,
            timeZoneIdentifier: timeZoneIdentifier,
            latitude: latitude,
            longitude: longitude
        )
    }

    init(location: WorldLocation) {
        self.init(
            city: location.city,
            country: location.country,
            countryCode: location.countryCode,
            timeZoneIdentifier: location.timeZoneIdentifier,
            latitude: location.coordinate?.latitude,
            longitude: location.coordinate?.longitude
        )
    }

    var coordinate: CLLocationCoordinate2D? {
        guard let latitude, let longitude else {
            return nil
        }

        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    var worldLocation: WorldLocation {
        WorldLocation(
            id: id,
            city: city,
            country: country,
            countryCode: countryCode,
            timeZoneIdentifier: timeZoneIdentifier,
            coordinate: coordinate,
            source: .search
        )
    }

    private static func makeID(
        city: String,
        country: String,
        timeZoneIdentifier: String,
        latitude: Double?,
        longitude: Double?
    ) -> String {
        let normalizedCity = city.normalizedFavoriteToken
        let normalizedCountry = country.normalizedFavoriteToken
        let normalizedTimeZone = timeZoneIdentifier.normalizedFavoriteToken
        let coordinateToken = [latitude, longitude]
            .compactMap { value in
                value.map { String(format: "%.4f", $0) }
            }
            .joined(separator: "_")

        return [normalizedCity, normalizedCountry, normalizedTimeZone, coordinateToken]
            .filter { !$0.isEmpty }
            .joined(separator: "|")
    }
}

private extension String {
    var normalizedFavoriteToken: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
            .replacingOccurrences(of: "[^a-z0-9]+", with: "-", options: .regularExpression)
            .trimmingCharacters(in: CharacterSet(charactersIn: "-"))
    }
}
