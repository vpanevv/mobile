import SwiftData

/// The app's single SwiftData container, shared between the SwiftUI scene and
/// App Intents (Siri / Shortcuts / Spotlight) so both read and write the same
/// store without racing separate containers.
enum AppModelContainer {
    static let shared: ModelContainer = makeContainer()

    private static func makeContainer() -> ModelContainer {
        let schema = Schema([
            UserProfile.self,
            Car.self,
            ServiceRecord.self,
            CarReminder.self,
            MechanicNote.self,
            CarDocument.self
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
}
