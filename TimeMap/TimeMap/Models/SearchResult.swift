import CoreLocation
import Foundation

struct SearchResult: Identifiable, Equatable {
    let id: String
    let title: String
    let subtitle: String
    let coordinate: CLLocationCoordinate2D
}
