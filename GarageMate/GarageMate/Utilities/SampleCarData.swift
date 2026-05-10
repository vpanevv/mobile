import Foundation
import SwiftData

enum SampleCarData {
    static let makes: [CarMake] = [
        CarMake(name: "BMW", models: ["1 Series", "2 Series", "3 Series", "4 Series", "5 Series", "7 Series", "X1", "X3", "X5", "X6"]),
        CarMake(name: "Audi", models: ["A3", "A4", "A5", "A6", "A7", "Q3", "Q5", "Q7", "Q8"]),
        CarMake(name: "Mercedes-Benz", models: ["A-Class", "C-Class", "E-Class", "S-Class", "GLA", "GLC", "GLE", "GLS"]),
        CarMake(name: "Volkswagen", models: ["Golf", "Passat", "Polo", "Tiguan", "Touareg", "Arteon", "T-Roc"]),
        CarMake(name: "Toyota", models: ["Corolla", "Camry", "Yaris", "RAV4", "Land Cruiser", "Prius", "C-HR"]),
        CarMake(name: "Honda", models: ["Civic", "Accord", "CR-V", "HR-V", "Jazz"]),
        CarMake(name: "Ford", models: ["Fiesta", "Focus", "Mondeo", "Kuga", "Puma", "Mustang"]),
        CarMake(name: "Opel", models: ["Corsa", "Astra", "Insignia", "Mokka", "Crossland", "Grandland"]),
        CarMake(name: "Peugeot", models: ["208", "308", "508", "2008", "3008", "5008"]),
        CarMake(name: "Renault", models: ["Clio", "Megane", "Captur", "Kadjar", "Koleos"]),
        CarMake(name: "Tesla", models: ["Model 3", "Model Y", "Model S", "Model X"]),
        CarMake(name: "Porsche", models: ["911", "Cayenne", "Macan", "Panamera", "Taycan"])
    ]

    static func demoProfile() -> UserProfile {
        let profile = UserProfile(
            appleUserID: "demo.garagemate.local",
            name: "Alex Driver",
            email: "alex@example.com",
            preferredCurrencyCode: "EUR",
            mileageUnit: "km"
        )

        let car = Car(
            make: "BMW",
            model: "3 Series",
            year: 2021,
            trim: "330i",
            plateNumber: "GM 2021",
            currentMileage: 48620,
            mileageUnit: "km"
        )

        car.serviceRecords = [
            ServiceRecord(title: "Oil and filter", category: .oil, date: .now.addingTimeInterval(-30 * 24 * 60 * 60), mileage: 48100, amountMinor: 16900, currencyCode: "EUR", shopName: "Autohaus Sofia", notes: "Used 5W-30 synthetic."),
            ServiceRecord(title: "Annual insurance", category: .insurance, date: .now.addingTimeInterval(-120 * 24 * 60 * 60), amountMinor: 64000, currencyCode: "EUR", shopName: "EuroIns")
        ]

        car.reminders = [
            CarReminder(title: "Next oil change", reminderType: .oilChange, dueDate: .now.addingTimeInterval(150 * 24 * 60 * 60), dueMileage: 58100, reminderDate: .now.addingTimeInterval(135 * 24 * 60 * 60)),
            CarReminder(title: "Inspection renewal", reminderType: .inspection, dueDate: .now.addingTimeInterval(55 * 24 * 60 * 60), reminderDate: .now.addingTimeInterval(45 * 24 * 60 * 60))
        ]

        car.mechanicNotes = [
            MechanicNote(text: "Slight vibration above 120 km/h. Check wheel balance next visit.", date: .now.addingTimeInterval(-9 * 24 * 60 * 60), mileage: 48420, priority: .medium),
            MechanicNote(text: "Rear brake pads still look good.", date: .now.addingTimeInterval(-31 * 24 * 60 * 60), mileage: 48100, priority: .low)
        ]

        profile.cars = [car]
        return profile
    }

    @MainActor
    static var previewContainer: ModelContainer {
        let schema = Schema([UserProfile.self, Car.self, ServiceRecord.self, CarReminder.self, MechanicNote.self])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container: ModelContainer
        do {
            container = try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            preconditionFailure("Could not create GarageMate preview container: \(error)")
        }
        container.mainContext.insert(demoProfile())
        return container
    }
}
