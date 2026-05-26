import CoreTransferable
import PhotosUI
import SwiftData
import SwiftUI
import UIKit
import UniformTypeIdentifiers

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @AppStorage("MyGarageMate.isSignedIn") private var isSignedIn = true
    @AppStorage("MyGarageMate.activeProfileID") private var activeProfileID = ""
    @Bindable var profile: UserProfile

    @State private var selectedProfilePhotoItem: PhotosPickerItem?
    @State private var destructiveAction: DestructiveAction?
    @State private var isLoadingProfilePhoto = false
    @State private var photoErrorMessage: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 22) {
                    profileHeader
                    profilePhotoAction

                    settingsGroup {
                        settingsInfoRow(
                            title: "My Profile",
                            subtitle: profile.email ?? "Local profile",
                            symbol: "person.crop.circle.fill",
                            color: .red
                        )

                        Divider().padding(.leading, 72)

                        settingsInfoRow(
                            title: "My Garage",
                            subtitle: "\(profile.cars.count) \(profile.cars.count == 1 ? "car" : "cars") saved",
                            symbol: "car.2.fill",
                            color: .blue
                        )
                    }

                    settingsGroup {
                        settingsMenuRow(
                            title: "Currency",
                            value: profile.preferredCurrencyCode,
                            symbol: "creditcard.fill",
                            color: .green
                        ) {
                            Button("EUR") { updateCurrency("EUR") }
                            Button("USD") { updateCurrency("USD") }
                        }

                        Divider().padding(.leading, 72)

                        settingsMenuRow(
                            title: "Mileage Unit",
                            value: profile.mileageUnit,
                            symbol: "gauge.with.dots.needle.67percent",
                            color: .orange
                        ) {
                            Button("km") { updateMileageUnit("km") }
                            Button("mi") { updateMileageUnit("mi") }
                        }
                    }

                    settingsGroup {
                        settingsInfoRow(
                            title: "Notifications",
                            subtitle: "Local service reminders",
                            symbol: "bell.badge.fill",
                            color: .red
                        )

                        Divider().padding(.leading, 72)

                        settingsInfoRow(
                            title: "Storage",
                            subtitle: "Data stays on this device",
                            symbol: "externaldrive.fill",
                            color: .green
                        )

                        Divider().padding(.leading, 72)

                        settingsInfoRow(
                            title: "App Version",
                            subtitle: "1.0",
                            symbol: "info.circle.fill",
                            color: .cyan
                        )
                    }

                    #if DEBUG
                    settingsGroup {
                        destructiveRow(
                            title: "Reset Demo Data",
                            symbol: "sparkles",
                            color: .purple,
                            action: .resetDemoData
                        )

                        Divider().padding(.leading, 72)

                        destructiveRow(
                            title: "Delete All Local Data",
                            symbol: "trash.fill",
                            color: .red,
                            action: .deleteAllData
                        )
                    }
                    #endif

                    settingsGroup {
                        destructiveRow(
                            title: "Sign Out",
                            symbol: "rectangle.portrait.and.arrow.right",
                            color: .red,
                            action: .signOut
                        )
                    }
                }
                .padding(.horizontal, 18)
                .padding(.top, 20)
                .padding(.bottom, 26)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
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

    private var profileHeader: some View {
        VStack(spacing: 14) {
            PhotosPicker(selection: $selectedProfilePhotoItem, matching: .images, preferredItemEncoding: .compatible) {
                profilePhoto
            }
            .buttonStyle(.plain)
            .accessibilityLabel(profile.avatarData == nil ? "Add profile photo" : "Change profile photo")

            VStack(spacing: 4) {
                Text(profile.name)
                    .font(.largeTitle.bold())
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.78)

                Text(profile.email ?? "Local MyGarageMate profile")
                    .font(.title3)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            if let photoErrorMessage {
                Text(photoErrorMessage)
                    .font(.footnote)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 4)
    }

    private var profilePhoto: some View {
        ZStack(alignment: .bottomTrailing) {
            Group {
                if isLoadingProfilePhoto {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(.thinMaterial)
                } else if let avatarData = profile.avatarData, let uiImage = UIImage(data: avatarData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                } else {
                    Image(systemName: "person.crop.circle.fill")
                        .font(.system(size: 86))
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(.blue)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(.thinMaterial)
                }
            }
            .frame(width: 116, height: 116)
            .clipShape(Circle())
            .overlay {
                Circle()
                    .strokeBorder(Color(.systemBackground), lineWidth: 4)
            }
            .shadow(color: .black.opacity(0.08), radius: 18, y: 8)

            Image(systemName: "camera.fill")
                .font(.headline.weight(.bold))
                .foregroundStyle(.white)
                .frame(width: 34, height: 34)
                .background(.blue.gradient, in: Circle())
                .overlay {
                    Circle()
                        .strokeBorder(Color(.systemBackground), lineWidth: 3)
                }
                .accessibilityHidden(true)
        }
        .frame(width: 124, height: 124)
    }

    private var profilePhotoAction: some View {
        VStack(spacing: 10) {
            PhotosPicker(selection: $selectedProfilePhotoItem, matching: .images, preferredItemEncoding: .compatible) {
                Label(profile.avatarData == nil ? "Add Profile Photo" : "Change Profile Photo", systemImage: "camera.badge.ellipsis")
                    .font(.headline)
                    .foregroundStyle(.blue)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 22)
                    .padding(.vertical, 18)
                    .background(Color(.secondarySystemGroupedBackground), in: Capsule())
            }
            .buttonStyle(.plain)
            .disabled(isLoadingProfilePhoto)
            .accessibilityLabel(profile.avatarData == nil ? "Add profile photo" : "Change profile photo")

            if profile.avatarData != nil {
                Button(role: .destructive) {
                    destructiveAction = .removeProfilePhoto
                } label: {
                    Label("Delete Profile Photo", systemImage: "trash.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 22)
                        .padding(.vertical, 18)
                        .background(Color(.secondarySystemGroupedBackground), in: Capsule())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Delete profile photo")
            }
        }
    }

    private func settingsGroup<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(spacing: 0) {
            content()
        }
        .padding(.vertical, 10)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 28, style: .continuous))
    }

    private func settingsInfoRow(title: String, subtitle: String? = nil, symbol: String, color: Color) -> some View {
        HStack(spacing: 16) {
            symbolTile(symbol: symbol, color: color)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.title3)
                    .foregroundStyle(.primary)
                if let subtitle {
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 10)
        .accessibilityElement(children: .combine)
    }

    private func settingsMenuRow<Content: View>(
        title: String,
        value: String,
        symbol: String,
        color: Color,
        @ViewBuilder menuContent: @escaping () -> Content
    ) -> some View {
        Menu {
            menuContent()
        } label: {
            HStack(spacing: 16) {
                symbolTile(symbol: symbol, color: color)

                Text(title)
                    .font(.title3)
                    .foregroundStyle(.primary)

                Spacer()

                Text(value)
                    .font(.title3)
                    .foregroundStyle(.secondary)

                Image(systemName: "chevron.right")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 18)
            .padding(.vertical, 10)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
        .accessibilityLabel("\(title), \(value)")
    }

    private func destructiveRow(title: String, symbol: String, color: Color, action: DestructiveAction) -> some View {
        Button(role: action.role) {
            destructiveAction = action
        } label: {
            HStack(spacing: 16) {
                symbolTile(symbol: symbol, color: color)

                Text(title)
                    .font(.title3)
                    .foregroundStyle(action.role == .destructive ? .red : .primary)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 10)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
    }

    private func symbolTile(symbol: String, color: Color) -> some View {
        Image(systemName: symbol)
            .font(.title3.weight(.semibold))
            .foregroundStyle(.white)
            .frame(width: 46, height: 46)
            .background(color.gradient, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .accessibilityHidden(true)
    }

    private func updateCurrency(_ currencyCode: String) {
        profile.preferredCurrencyCode = currencyCode
        saveSettings()
    }

    private func updateMileageUnit(_ mileageUnit: String) {
        profile.mileageUnit = mileageUnit
        saveSettings()
    }

    private func saveSettings() {
        do {
            try modelContext.save()
            HapticsManager.lightTap()
        } catch {
            assertionFailure("Failed to save settings: \(error)")
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
        case .removeProfilePhoto:
            profile.avatarData = nil
            selectedProfilePhotoItem = nil
            photoErrorMessage = nil
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
        guard let item else {
            isLoadingProfilePhoto = false
            photoErrorMessage = nil
            return
        }

        isLoadingProfilePhoto = true
        photoErrorMessage = nil

        do {
            let imageData = try await loadImageData(from: item)
            guard
                let image = UIImage(data: imageData),
                let jpegData = compressedProfilePhotoData(from: image)
            else {
                isLoadingProfilePhoto = false
                photoErrorMessage = "Could not read that photo. Please try another image."
                HapticsManager.warning()
                return
            }

            profile.avatarData = jpegData
            isLoadingProfilePhoto = false
        } catch {
            isLoadingProfilePhoto = false
            photoErrorMessage = "Could not load that photo. Please try another image."
            HapticsManager.warning()
            return
        }

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

    private func loadImageData(from item: PhotosPickerItem) async throws -> Data {
        if let photo = try? await item.loadTransferable(type: SettingsPickedPhoto.self) {
            return photo.data
        }

        if let data = try? await item.loadTransferable(type: Data.self) {
            return data
        }

        throw ProfilePhotoImportError.couldNotLoadData
    }
}

private struct SettingsPickedPhoto: Transferable {
    let data: Data

    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(importedContentType: .jpeg) { data in
            SettingsPickedPhoto(data: data)
        }
        DataRepresentation(importedContentType: .png) { data in
            SettingsPickedPhoto(data: data)
        }
        DataRepresentation(importedContentType: .heic) { data in
            SettingsPickedPhoto(data: data)
        }
        DataRepresentation(importedContentType: .image) { data in
            SettingsPickedPhoto(data: data)
        }
    }
}

private enum ProfilePhotoImportError: Error {
    case couldNotLoadData
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
