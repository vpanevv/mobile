import PhotosUI
import SwiftData
import SwiftUI
import UIKit

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @AppStorage("MyGarageMate.isSignedIn") private var isSignedIn = true
    @AppStorage("MyGarageMate.activeProfileID") private var activeProfileID = ""
    @Bindable var profile: UserProfile

    @State private var selectedProfilePhotoItem: PhotosPickerItem?
    @State private var serviceReportURL: URL?
    @State private var serviceReportMessage: String?
    @State private var isGeneratingServiceReport = false
    @State private var destructiveAction: DestructiveAction?

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack(spacing: 14) {
                        PhotosPicker(selection: $selectedProfilePhotoItem, matching: .images) {
                            profilePhoto
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Choose profile photo")
                        .contextMenu {
                            if profile.avatarData != nil {
                                Button(role: .destructive) {
                                    destructiveAction = .removeProfilePhoto
                                } label: {
                                    Label("Remove Profile Photo", systemImage: "trash")
                                }
                            }
                        }

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

                Section("Reports") {
                    Button {
                        generateServiceReport()
                    } label: {
                        Label("Generate Services Report", systemImage: "doc.richtext")
                    }
                    .disabled(isGeneratingServiceReport)
                    .accessibilityLabel("Generate services report")

                    if let serviceReportURL {
                        ShareLink(item: serviceReportURL) {
                            Label("Share Services Report", systemImage: "square.and.arrow.up")
                        }
                        .accessibilityLabel("Share services report")
                    }

                    if let serviceReportMessage {
                        Text(serviceReportMessage)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
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
            .onChange(of: selectedProfilePhotoItem) { _, newValue in
                Task {
                    await updateProfilePhoto(from: newValue)
                }
            }
        }
    }

    @ViewBuilder
    private var profilePhoto: some View {
        ZStack(alignment: .bottomTrailing) {
            Group {
                if let avatarData = profile.avatarData, let uiImage = UIImage(data: avatarData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                } else {
                    Image(systemName: "person.crop.circle.fill")
                        .font(.system(size: 66))
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(.tint)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(.thinMaterial)
                }
            }
            .frame(width: 68, height: 68)
            .clipShape(Circle())
            .overlay {
                Circle()
                    .strokeBorder(.white.opacity(0.58), lineWidth: 1)
            }

            Image(systemName: "camera.fill")
                .font(.caption.weight(.bold))
                .foregroundStyle(.white)
                .frame(width: 25, height: 25)
                .background(.blue.gradient, in: Circle())
                .overlay {
                    Circle()
                        .strokeBorder(Color(.systemBackground), lineWidth: 2)
                }
                .accessibilityHidden(true)
        }
        .frame(width: 74, height: 74)
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
        case .removeProfilePhoto:
            profile.avatarData = nil
        }

        do {
            try modelContext.save()
            HapticsManager.success()
        } catch {
            assertionFailure("Failed to update settings data: \(error)")
        }

        destructiveAction = nil
    }

    @MainActor
    private func updateProfilePhoto(from item: PhotosPickerItem?) async {
        guard
            let data = try? await item?.loadTransferable(type: Data.self),
            let image = UIImage(data: data),
            let jpegData = compressedProfilePhotoData(from: image)
        else { return }

        profile.avatarData = jpegData

        do {
            try modelContext.save()
            HapticsManager.success()
        } catch {
            assertionFailure("Failed to save profile photo: \(error)")
        }
    }

    private func compressedProfilePhotoData(from image: UIImage) -> Data? {
        let maxLength: CGFloat = 768
        let longestSide = max(image.size.width, image.size.height)
        let scale = longestSide > maxLength ? maxLength / longestSide : 1
        let targetSize = CGSize(width: image.size.width * scale, height: image.size.height * scale)

        let renderer = UIGraphicsImageRenderer(size: targetSize)
        let resizedImage = renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: targetSize))
        }

        return resizedImage.jpegData(compressionQuality: 0.84)
    }

    private func generateServiceReport() {
        isGeneratingServiceReport = true
        serviceReportURL = nil
        serviceReportMessage = nil

        do {
            let url = try ServiceReportExporter.makePDF(for: profile)
            serviceReportURL = url
            serviceReportMessage = "Report ready: \(url.lastPathComponent)"
            HapticsManager.success()
        } catch {
            serviceReportMessage = error.localizedDescription
            HapticsManager.warning()
        }

        isGeneratingServiceReport = false
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
    case removeProfilePhoto
    case signOut

    var id: String { title }

    var title: String {
        switch self {
        #if DEBUG
        case .resetDemoData: "Reset demo data?"
        case .deleteAllData: "Delete all local data?"
        #endif
        case .removeProfilePhoto: "Remove profile photo?"
        case .signOut: "Sign out?"
        }
    }

    var message: String {
        switch self {
        #if DEBUG
        case .resetDemoData:
            "This replaces current local MyGarageMate data with the sample garage."
        case .deleteAllData:
            "This permanently removes the local profile, cars, service history, reminders, and notes."
        #endif
        case .removeProfilePhoto:
            "This removes the selected profile photo from local MyGarageMate data."
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
        case .removeProfilePhoto: "Remove Photo"
        case .signOut: "Sign Out"
        }
    }

    var role: ButtonRole? {
        switch self {
        #if DEBUG
        case .resetDemoData: nil
        case .deleteAllData: .destructive
        #endif
        case .removeProfilePhoto: .destructive
        case .signOut: .destructive
        }
    }
}
