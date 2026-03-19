import CoreLocation
import MapKit

final class LocationSearchService {
    func searchCities(matching query: String) async throws -> [SearchResult] {
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedQuery.isEmpty else {
            return []
        }

        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = trimmedQuery
        request.resultTypes = .address

        let response = try await MKLocalSearch(request: request).start()
        var seen = Set<String>()

        return response.mapItems.compactMap { item in
            let placemark = item.placemark
            guard let coordinate = placemark.location?.coordinate else {
                return nil
            }

            let city = placemark.locality ?? placemark.subAdministrativeArea ?? placemark.name
            let country = placemark.country
            guard let city, let country else {
                return nil
            }

            let key = "\(city.lowercased())-\(country.lowercased())"
            guard seen.insert(key).inserted else {
                return nil
            }

            let subtitleParts = [placemark.administrativeArea, country].compactMap { $0 }
            return SearchResult(
                id: key,
                title: city,
                subtitle: subtitleParts.joined(separator: ", "),
                coordinate: coordinate
            )
        }
    }
}
