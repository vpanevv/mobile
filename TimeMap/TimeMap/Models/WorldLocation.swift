import CoreLocation
import Foundation

struct WorldLocation: Identifiable, Equatable {
    enum Source: String, Equatable {
        case search
        case map
        case local
    }

    let id: String
    let city: String
    let country: String
    let countryCode: String?
    let timeZoneIdentifier: String
    let coordinate: CLLocationCoordinate2D?
    let source: Source

    init(
        id: String = UUID().uuidString,
        city: String,
        country: String,
        countryCode: String?,
        timeZoneIdentifier: String,
        coordinate: CLLocationCoordinate2D?,
        source: Source
    ) {
        self.id = id
        self.city = city
        self.country = country
        self.countryCode = countryCode
        self.timeZoneIdentifier = timeZoneIdentifier
        self.coordinate = coordinate
        self.source = source
    }
}

extension CLLocationCoordinate2D: @retroactive Equatable {
    public static func == (lhs: CLLocationCoordinate2D, rhs: CLLocationCoordinate2D) -> Bool {
        abs(lhs.latitude - rhs.latitude) < 0.000_001 && abs(lhs.longitude - rhs.longitude) < 0.000_001
    }
}
