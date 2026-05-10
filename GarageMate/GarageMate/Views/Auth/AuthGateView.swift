import SwiftData
import SwiftUI

struct AuthGateView: View {
    @AppStorage("GarageMate.isSignedIn") private var isSignedIn = false
    @AppStorage("GarageMate.activeProfileID") private var activeProfileID = ""
    @Query(sort: \UserProfile.createdAt, order: .forward) private var profiles: [UserProfile]

    var body: some View {
        Group {
            if let profile = activeProfile, isSignedIn {
                MainTabView(profile: profile)
            } else {
                SignInView()
            }
        }
        .animation(.snappy, value: isSignedIn)
        .animation(.snappy, value: profiles.count)
    }

    private var activeProfile: UserProfile? {
        profiles.first { $0.id.uuidString == activeProfileID } ?? profiles.first
    }
}
