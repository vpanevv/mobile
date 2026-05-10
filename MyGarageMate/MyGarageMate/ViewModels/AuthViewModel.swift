import AuthenticationServices
import Combine
import Foundation
import SwiftData

@MainActor
final class AuthViewModel: ObservableObject {
    @Published var errorMessage: String?

    func handleAppleResult(_ result: Result<ASAuthorization, Error>, modelContext: ModelContext) {
        switch result {
        case .success(let authorization):
            guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else {
                errorMessage = "Apple sign-in did not return a valid credential."
                return
            }

            let formatter = PersonNameComponentsFormatter()
            let providedName = credential.fullName.flatMap { formatter.string(from: $0).nilIfBlank }

            createOrUpdateProfile(
                appleUserID: credential.user,
                name: providedName ?? "MyGarageMate Driver",
                email: credential.email,
                modelContext: modelContext
            )
        case .failure(let error):
            errorMessage = error.localizedDescription
        }
    }

    func continueWithoutApple(modelContext: ModelContext) {
        createOrUpdateProfile(
            appleUserID: "demo.mygaragemate.local",
            name: "MyGarageMate Driver",
            email: nil,
            modelContext: modelContext
        )
    }

    private func createOrUpdateProfile(
        appleUserID: String,
        name: String,
        email: String?,
        modelContext: ModelContext
    ) {
        do {
            let descriptor = FetchDescriptor<UserProfile>(
                predicate: #Predicate { profile in
                    profile.appleUserID == appleUserID
                }
            )

            let profile: UserProfile
            if let existingProfile = try modelContext.fetch(descriptor).first {
                existingProfile.name = existingProfile.name.isEmpty ? name : existingProfile.name
                if existingProfile.email == nil {
                    existingProfile.email = email
                }
                profile = existingProfile
            } else {
                let newProfile = UserProfile(appleUserID: appleUserID, name: name, email: email)
                modelContext.insert(newProfile)
                profile = newProfile
            }

            try modelContext.save()
            UserDefaults.standard.set(true, forKey: "MyGarageMate.isSignedIn")
            UserDefaults.standard.set(profile.id.uuidString, forKey: "MyGarageMate.activeProfileID")
            HapticsManager.success()
        } catch {
            errorMessage = "Could not save your profile. \(error.localizedDescription)"
        }
    }
}

private extension String {
    var nilIfBlank: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
