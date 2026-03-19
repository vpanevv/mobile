import CoreLocation
import Foundation

final class LocationResolver {
    private let geocoder = CLGeocoder()

    func resolve(coordinate: CLLocationCoordinate2D, source: WorldLocation.Source) async throws -> WorldLocation {
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        let placemarks = try await geocoder.reverseGeocodeLocation(location)

        guard let placemark = placemarks.first else {
            throw ResolverError.noLocationFound
        }

        let city = placemark.locality
            ?? placemark.subAdministrativeArea
            ?? placemark.name
            ?? "Unknown Place"

        let country = placemark.country ?? "Unknown Country"
        let timeZoneIdentifier = placemark.timeZone?.identifier ?? TimeZone.autoupdatingCurrent.identifier

        return WorldLocation(
            city: city,
            country: country,
            countryCode: placemark.isoCountryCode,
            timeZoneIdentifier: timeZoneIdentifier,
            coordinate: coordinate,
            source: source
        )
    }

    enum ResolverError: LocalizedError {
        case noLocationFound

        var errorDescription: String? {
            switch self {
            case .noLocationFound:
                return "No meaningful location was found for that point."
            }
        }
    }
}
