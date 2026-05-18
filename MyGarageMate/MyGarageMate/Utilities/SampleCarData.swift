import Foundation
import SwiftData

enum SampleCarData {
    static let makes: [CarMake] = [
        CarMake(name: "BMW", models: ["1 Series", "2 Series", "3 Series", "4 Series", "5 Series", "7 Series", "8 Series", "i3", "i4", "i5", "i7", "iX", "X1", "X2", "X3", "X4", "X5", "X6", "X7", "Z4"]),
        CarMake(name: "Audi", models: ["A1", "A3", "A4", "A5", "A6", "A7", "A8", "e-tron GT", "Q2", "Q3", "Q4 e-tron", "Q5", "Q7", "Q8", "TT", "R8"]),
        CarMake(name: "Mercedes-Benz", models: ["A-Class", "B-Class", "C-Class", "CLA", "CLS", "E-Class", "S-Class", "EQA", "EQB", "EQC", "EQE", "EQS", "G-Class", "GLA", "GLB", "GLC", "GLE", "GLS"]),
        CarMake(name: "Volkswagen", models: ["Golf", "Passat", "Polo", "Tiguan", "Touareg", "Arteon", "T-Roc", "T-Cross", "ID.3", "ID.4", "ID.5", "ID.7", "Touran", "Sharan"]),
        CarMake(name: "Toyota", models: ["Aygo", "Corolla", "Camry", "Yaris", "Yaris Cross", "RAV4", "Highlander", "Land Cruiser", "Prius", "C-HR", "Supra", "Hilux", "bZ4X"]),
        CarMake(name: "Honda", models: ["Civic", "Accord", "CR-V", "HR-V", "Jazz", "e", "ZR-V", "NSX"]),
        CarMake(name: "Ford", models: ["Fiesta", "Focus", "Mondeo", "Kuga", "Puma", "Mustang", "Mustang Mach-E", "Explorer", "Ranger", "Transit"]),
        CarMake(name: "Opel", models: ["Corsa", "Astra", "Insignia", "Mokka", "Crossland", "Grandland", "Combo", "Zafira"]),
        CarMake(name: "Peugeot", models: ["208", "308", "408", "508", "2008", "3008", "5008", "Rifter", "Traveller"]),
        CarMake(name: "Renault", models: ["Clio", "Megane", "Megane E-Tech", "Captur", "Kadjar", "Austral", "Koleos", "Scenic", "Talisman", "Zoe"]),
        CarMake(name: "Tesla", models: ["Model 3", "Model Y", "Model S", "Model X", "Cybertruck", "Roadster"]),
        CarMake(name: "Porsche", models: ["718 Cayman", "718 Boxster", "911", "Cayenne", "Macan", "Panamera", "Taycan"]),
        CarMake(name: "Lexus", models: ["CT", "IS", "ES", "GS", "LS", "UX", "NX", "RX", "RZ", "GX", "LX", "LC", "RC"]),
        CarMake(name: "Ferrari", models: ["296 GTB", "296 GTS", "488", "812 Superfast", "812 GTS", "F8 Tributo", "Portofino", "Roma", "SF90 Stradale", "SF90 Spider", "Purosangue"]),
        CarMake(name: "Nissan", models: ["Micra", "Juke", "Qashqai", "X-Trail", "Leaf", "Ariya", "GT-R", "Navara"]),
        CarMake(name: "Hyundai", models: ["i10", "i20", "i30", "Bayon", "Kona", "Tucson", "Santa Fe", "Ioniq 5", "Ioniq 6"]),
        CarMake(name: "Kia", models: ["Picanto", "Rio", "Ceed", "Stonic", "Niro", "Sportage", "Sorento", "EV3", "EV6", "EV9"]),
        CarMake(name: "Mazda", models: ["Mazda2", "Mazda3", "Mazda6", "CX-3", "CX-30", "CX-5", "CX-60", "MX-5", "MX-30"]),
        CarMake(name: "Skoda", models: ["Fabia", "Scala", "Octavia", "Superb", "Kamiq", "Karoq", "Kodiaq", "Enyaq"]),
        CarMake(name: "Seat", models: ["Ibiza", "Leon", "Arona", "Ateca", "Tarraco", "Alhambra"]),
        CarMake(name: "Cupra", models: ["Born", "Leon", "Formentor", "Ateca", "Tavascan"]),
        CarMake(name: "Volvo", models: ["EX30", "EX40", "EX90", "S60", "S90", "V60", "V90", "XC40", "XC60", "XC90"]),
        CarMake(name: "Jaguar", models: ["XE", "XF", "F-Type", "E-Pace", "F-Pace", "I-Pace"]),
        CarMake(name: "Land Rover", models: ["Defender", "Discovery", "Discovery Sport", "Range Rover", "Range Rover Sport", "Range Rover Velar", "Range Rover Evoque"]),
        CarMake(name: "Alfa Romeo", models: ["Giulia", "Stelvio", "Tonale", "Junior", "4C"]),
        CarMake(name: "Fiat", models: ["500", "500e", "500X", "Panda", "Tipo", "Doblo"]),
        CarMake(name: "Mini", models: ["Cooper", "Clubman", "Countryman", "Convertible", "Aceman"]),
        CarMake(name: "Mitsubishi", models: ["Space Star", "ASX", "Eclipse Cross", "Outlander", "L200"]),
        CarMake(name: "Subaru", models: ["Impreza", "Levorg", "Outback", "Forester", "XV", "BRZ", "Solterra"]),
        CarMake(name: "Suzuki", models: ["Swift", "Ignis", "Vitara", "S-Cross", "Jimny", "Across"]),
        CarMake(name: "Dacia", models: ["Sandero", "Logan", "Duster", "Jogger", "Spring"]),
        CarMake(name: "Citroen", models: ["C3", "C3 Aircross", "C4", "C4 X", "C5 Aircross", "Berlingo", "Spacetourer"]),
        CarMake(name: "Maserati", models: ["Ghibli", "Quattroporte", "Levante", "Grecale", "GranTurismo", "MC20"]),
        CarMake(name: "Lamborghini", models: ["Huracan", "Aventador", "Revuelto", "Urus", "Gallardo"]),
        CarMake(name: "Bentley", models: ["Continental GT", "Flying Spur", "Bentayga", "Mulsanne"]),
        CarMake(name: "Rolls-Royce", models: ["Ghost", "Phantom", "Cullinan", "Spectre", "Wraith", "Dawn"]),
        CarMake(name: "Aston Martin", models: ["Vantage", "DB11", "DB12", "DBX", "DBS", "Valhalla"]),
        CarMake(name: "McLaren", models: ["540C", "570S", "600LT", "720S", "750S", "Artura", "GT"]),
        CarMake(name: "Chevrolet", models: ["Spark", "Cruze", "Malibu", "Camaro", "Corvette", "Trax", "Tahoe", "Suburban"]),
        CarMake(name: "Jeep", models: ["Renegade", "Compass", "Cherokee", "Grand Cherokee", "Wrangler", "Avenger", "Gladiator"]),
        CarMake(name: "BYD", models: ["Dolphin", "Atto 3", "Seal", "Seal U", "Tang", "Han"]),
        CarMake(name: "Polestar", models: ["2", "3", "4"])
    ]

    static func demoProfile() -> UserProfile {
        let profile = UserProfile(
            appleUserID: "demo.mygaragemate.local",
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
            mileageUnit: "km",
            engineType: .gasoline
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
            preconditionFailure("Could not create MyGarageMate preview container: \(error)")
        }
        container.mainContext.insert(demoProfile())
        return container
    }
}
