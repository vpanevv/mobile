import SwiftData
import SwiftUI

@main
struct MyGarageMateApp: App {
    private let modelContainer = Self.makeModelContainer()

    private static func makeModelContainer() -> ModelContainer {
        let schema = Schema([
            UserProfile.self,
            Car.self,
            ServiceRecord.self,
            CarReminder.self,
            MechanicNote.self
        ])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            let fallbackConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
            do {
                return try ModelContainer(for: schema, configurations: [fallbackConfiguration])
            } catch {
                preconditionFailure("Could not create MyGarageMate SwiftData container: \(error)")
            }
        }
    }

    var body: some Scene {
        WindowGroup {
            AppLaunchView()
        }
        .modelContainer(modelContainer)
    }
}
