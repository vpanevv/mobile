import Foundation
import SwiftData

@Model
final class UserProfile {
    var id: UUID
    @Attribute(.unique) var appleUserID: String
    var name: String
    var email: String?
    var avatarData: Data?
    var preferredCurrencyCode: String
    var mileageUnit: String
    var createdAt: Date

    @Relationship(deleteRule: .cascade, inverse: \Car.owner)
    var cars: [Car] = []

    init(
        id: UUID = UUID(),
        appleUserID: String,
        name: String,
        email: String? = nil,
        avatarData: Data? = nil,
        preferredCurrencyCode: String = "EUR",
        mileageUnit: String = "km",
        createdAt: Date = .now,
        cars: [Car] = []
    ) {
        self.id = id
        self.appleUserID = appleUserID
        self.name = name
        self.email = email
        self.avatarData = avatarData
        self.preferredCurrencyCode = preferredCurrencyCode
        self.mileageUnit = mileageUnit
        self.createdAt = createdAt
        self.cars = cars
    }
}
