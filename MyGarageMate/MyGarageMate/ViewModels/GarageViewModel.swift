import Combine
import Foundation

@MainActor
final class GarageViewModel: ObservableObject {
    func sortedCars(for profile: UserProfile) -> [Car] {
        profile.cars.sorted { lhs, rhs in
            if lhs.createdAt == rhs.createdAt {
                return lhs.displayName < rhs.displayName
            }
            return lhs.createdAt > rhs.createdAt
        }
    }

    func totalSpentThisYearText(for car: Car, currencyCode: String) -> String {
        CurrencyFormatter.string(fromMinor: car.totalSpentThisYear(currencyCode: currencyCode), currencyCode: currencyCode)
    }
}
