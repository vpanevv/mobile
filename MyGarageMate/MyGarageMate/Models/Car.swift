import Foundation
import SwiftData

@Model
final class Car {
    var id: UUID
    var make: String
    var model: String
    var year: Int
    var trim: String?
    var plateNumber: String?
    var vin: String?
    var currentMileage: Double
    var mileageUnit: String
    var photoData: Data?
    var createdAt: Date
    var owner: UserProfile?

    @Relationship(deleteRule: .cascade, inverse: \ServiceRecord.car)
    var serviceRecords: [ServiceRecord] = []

    @Relationship(deleteRule: .cascade, inverse: \CarReminder.car)
    var reminders: [CarReminder] = []

    @Relationship(deleteRule: .cascade, inverse: \MechanicNote.car)
    var mechanicNotes: [MechanicNote] = []

    init(
        id: UUID = UUID(),
        make: String,
        model: String,
        year: Int,
        trim: String? = nil,
        plateNumber: String? = nil,
        vin: String? = nil,
        currentMileage: Double = 0,
        mileageUnit: String = "km",
        photoData: Data? = nil,
        createdAt: Date = .now,
        serviceRecords: [ServiceRecord] = [],
        reminders: [CarReminder] = [],
        mechanicNotes: [MechanicNote] = []
    ) {
        self.id = id
        self.make = make
        self.model = model
        self.year = year
        self.trim = trim
        self.plateNumber = plateNumber
        self.vin = vin
        self.currentMileage = currentMileage
        self.mileageUnit = mileageUnit
        self.photoData = photoData
        self.createdAt = createdAt
        self.serviceRecords = serviceRecords
        self.reminders = reminders
        self.mechanicNotes = mechanicNotes
    }

    var displayName: String {
        "\(year) \(make) \(model)"
    }

    var serviceRecordsNewestFirst: [ServiceRecord] {
        serviceRecords.sorted { $0.date > $1.date }
    }

    var notesNewestFirst: [MechanicNote] {
        mechanicNotes.sorted { $0.date > $1.date }
    }

    var upcomingReminders: [CarReminder] {
        reminders.filter { !$0.isCompleted }.sorted(by: CarReminder.sortUpcoming)
    }

    var nextImportantReminder: CarReminder? {
        upcomingReminders.first
    }

    var lastService: ServiceRecord? {
        serviceRecordsNewestFirst.first
    }

    func totalSpentThisYear(currencyCode: String, now: Date = .now) -> Int {
        serviceRecords
            .filter { record in
                record.currencyCode == currencyCode &&
                Calendar.current.isDate(record.date, equalTo: now, toGranularity: .year)
            }
            .reduce(0) { $0 + $1.amountMinor }
    }
}
