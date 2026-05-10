import SwiftData
import SwiftUI

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @AppStorage("GarageMate.isSignedIn") private var isSignedIn = true
    @AppStorage("GarageMate.activeProfileID") private var activeProfileID = ""
    @Bindable var profile: UserProfile

    @State private var destructiveAction: DestructiveAction?

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack(spacing: 14) {
                        Image(systemName: "person.crop.circle.fill")
                            .font(.system(size: 44))
                            .symbolRenderingMode(.hierarchical)
                            .foregroundStyle(.tint)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(profile.name)
                                .font(.headline)
                            if let email = profile.email {
                                Text(email)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            } else {
                                Text("Local profile")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }

                Section("Preferences") {
                    Picker("Currency", selection: $profile.preferredCurrencyCode) {
                        Text("EUR").tag("EUR")
                        Text("USD").tag("USD")
                    }
                    .accessibilityLabel("Preferred currency")
                    Picker("Mileage Unit", selection: $profile.mileageUnit) {
                        Text("km").tag("km")
                        Text("mi").tag("mi")
                    }
                    .accessibilityLabel("Mileage unit")
                }

                #if DEBUG
                Section("Development") {
                    Button {
                        destructiveAction = .resetDemoData
                    } label: {
                        Label("Reset Demo Data", systemImage: "sparkles")
                    }

                    Button(role: .destructive) {
                        destructiveAction = .deleteAllData
                    } label: {
                        Label("Delete All Local Data", systemImage: "trash")
                    }
                }
                #endif

                Section {
                    HStack {
                        Text("App Version")
                        Spacer()
                        Text("1.0")
                            .foregroundStyle(.secondary)
                    }

                    Button(role: .destructive) {
                        destructiveAction = .signOut
                    } label: {
                        Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                    }
                }
            }
            .navigationTitle("Settings")
            .confirmationDialog(
                destructiveAction?.title ?? "",
                isPresented: Binding(
                    get: { destructiveAction != nil },
                    set: { if !$0 { destructiveAction = nil } }
                ),
                titleVisibility: .visible
            ) {
                if let destructiveAction {
                    Button(destructiveAction.confirmationTitle, role: destructiveAction.role) {
                        perform(destructiveAction)
                    }
                }
                Button("Cancel", role: .cancel) {
                    destructiveAction = nil
                }
            } message: {
                if let destructiveAction {
                    Text(destructiveAction.message)
                }
            }
        }
    }

    private func perform(_ action: DestructiveAction) {
        switch action {
        #if DEBUG
        case .resetDemoData:
            deleteProfiles()
            let demoProfile = SampleCarData.demoProfile()
            modelContext.insert(demoProfile)
            activeProfileID = demoProfile.id.uuidString
            isSignedIn = true
        case .deleteAllData:
            deleteProfiles()
            activeProfileID = ""
            isSignedIn = false
        #endif
        case .signOut:
            isSignedIn = false
        }

        do {
            try modelContext.save()
            HapticsManager.success()
        } catch {
            assertionFailure("Failed to update settings data: \(error)")
        }

        destructiveAction = nil
    }

    private func deleteProfiles() {
        do {
            let profiles = try modelContext.fetch(FetchDescriptor<UserProfile>())
            for profile in profiles {
                modelContext.delete(profile)
            }
        } catch {
            assertionFailure("Failed to fetch profiles for deletion: \(error)")
        }
    }
}

private enum DestructiveAction: Identifiable {
    #if DEBUG
    case resetDemoData
    case deleteAllData
    #endif
    case signOut

    var id: String { title }

    var title: String {
        switch self {
        #if DEBUG
        case .resetDemoData: "Reset demo data?"
        case .deleteAllData: "Delete all local data?"
        #endif
        case .signOut: "Sign out?"
        }
    }

    var message: String {
        switch self {
        #if DEBUG
        case .resetDemoData:
            "This replaces current local GarageMate data with the sample garage."
        case .deleteAllData:
            "This permanently removes the local profile, cars, service history, reminders, and notes."
        #endif
        case .signOut:
            "Your local data stays on this device. Sign in again to continue."
        }
    }

    var confirmationTitle: String {
        switch self {
        #if DEBUG
        case .resetDemoData: "Reset Demo Data"
        case .deleteAllData: "Delete Everything"
        #endif
        case .signOut: "Sign Out"
        }
    }

    var role: ButtonRole? {
        switch self {
        #if DEBUG
        case .resetDemoData: nil
        case .deleteAllData: .destructive
        #endif
        case .signOut: .destructive
        }
    }
}
