import Foundation
import SwiftData

enum ServiceCategory: String, CaseIterable, Codable, Identifiable {
    case oil
    case tires
    case brakes
    case engine
    case transmission
    case battery
    case suspension
    case insurance
    case inspection
    case other

    var id: String { rawValue }

    var title: String {
        switch self {
        case .oil: "Oil"
        case .tires: "Tires"
        case .brakes: "Brakes"
        case .engine: "Engine"
        case .transmission: "Transmission"
        case .battery: "Battery"
        case .suspension: "Suspension"
        case .insurance: "Insurance"
        case .inspection: "Inspection"
        case .other: "Other"
        }
    }

    var symbolName: String {
        switch self {
        case .oil: "oilcan.fill"
        case .tires: "circle.hexagongrid.fill"
        case .brakes: "exclamationmark.brakesignal"
        case .engine: "engine.combustion.fill"
        case .transmission: "gearshape.2.fill"
        case .battery: "battery.100percent"
        case .suspension: "wrench.adjustable.fill"
        case .insurance: "shield.checkered"
        case .inspection: "checklist.checked"
        case .other: "ellipsis.circle.fill"
        }
    }
}

@Model
final class ServiceRecord {
    var id: UUID
    var title: String
    var categoryRawValue: String
    var date: Date
    var mileage: Double?
    var amountMinor: Int
    var currencyCode: String
    var shopName: String?
    var notes: String?
    var receiptImageData: Data?
    var createdAt: Date
    var car: Car?

    var category: ServiceCategory {
        get { ServiceCategory(rawValue: categoryRawValue) ?? .other }
        set { categoryRawValue = newValue.rawValue }
    }

    init(
        id: UUID = UUID(),
        title: String,
        category: ServiceCategory,
        date: Date = .now,
        mileage: Double? = nil,
        amountMinor: Int = 0,
        currencyCode: String = "EUR",
        shopName: String? = nil,
        notes: String? = nil,
        receiptImageData: Data? = nil,
        createdAt: Date = .now
    ) {
        self.id = id
        self.title = title
        self.categoryRawValue = category.rawValue
        self.date = date
        self.mileage = mileage
        self.amountMinor = amountMinor
        self.currencyCode = currencyCode
        self.shopName = shopName
        self.notes = notes
        self.receiptImageData = receiptImageData
        self.createdAt = createdAt
    }
}
