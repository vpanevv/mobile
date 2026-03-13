import SwiftUI
import PhotosUI

#if canImport(UIKit)
import UIKit
private typealias PlatformImage = UIImage
#elseif canImport(AppKit)
import AppKit
private typealias PlatformImage = NSImage
#endif

struct ProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var store: AppStore

    @State private var name: String
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var photoData: Data?
    @State private var isLoadingPhoto = false

    init(profile: UserProfile) {
        _name = State(initialValue: profile.name)
        _photoData = State(initialValue: profile.photoData)
    }

    var body: some View {
        ZStack {
            AppBackground()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    topBar
                    profileHero
                    editorCard
                    footerNote
                }
                .padding(.horizontal, 20)
                .padding(.top, 18)
                .padding(.bottom, 36)
            }
        }
        .onChange(of: selectedPhotoItem) { _, newValue in
            guard let newValue else { return }

            Task {
                isLoadingPhoto = true
                defer { isLoadingPhoto = false }
                photoData = try? await newValue.loadTransferable(type: Data.self)
            }
        }
    }

    private var topBar: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(Color.white.opacity(0.1), in: Circle())
            }
            .buttonStyle(.plain)

            Spacer()

            VStack(spacing: 4) {
                Text("Profile")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(.white)

                Text("AI identity hub")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.58))
                    .textCase(.uppercase)
                    .tracking(1.1)
            }

            Spacer()

            Button(action: saveProfile) {
                Text("Save")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.black)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 11)
                    .background(Color.white, in: Capsule())
            }
            .buttonStyle(.plain)
            .disabled(trimmedName.isEmpty)
            .opacity(trimmedName.isEmpty ? 0.45 : 1)
        }
    }

    private var profileHero: some View {
        GlassCard {
            VStack(spacing: 18) {
                ProfileAvatarView(
                    name: trimmedName.isEmpty ? name : trimmedName,
                    photoData: photoData,
                    size: 128,
                    accentColor: .cyan
                )
                .overlay(alignment: .bottomTrailing) {
                    PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                        Image(systemName: "camera.fill")
                            .font(.headline.weight(.bold))
                            .foregroundStyle(.black)
                            .frame(width: 40, height: 40)
                            .background(
                                LinearGradient(
                                    colors: [Color.white, Color.cyan.opacity(0.85)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                in: Circle()
                            )
                    }
                    .buttonStyle(.plain)
                    .offset(x: 6, y: 6)
                }

                VStack(spacing: 8) {
                    Text(trimmedName.isEmpty ? "Your AI Daily Buddy" : trimmedName)
                        .font(.system(size: 30, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)

                    Text(isLoadingPhoto ? "Syncing profile picture..." : "Your planner identity travels with every task and every AI suggestion.")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.white.opacity(0.72))
                        .multilineTextAlignment(.center)
                }
            }
            .frame(maxWidth: .infinity)
        }
    }

    private var editorCard: some View {
        VStack(alignment: .leading, spacing: 18) {
            Label("Profile details", systemImage: "person.crop.circle.badge.sparkles")
                .font(.headline.weight(.bold))
                .foregroundStyle(Color.black.opacity(0.82))

            VStack(alignment: .leading, spacing: 10) {
                Text("Name")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Color.black.opacity(0.56))
                    .textCase(.uppercase)
                    .tracking(1.1)

                TextField("Your name", text: $name)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .background(Color.white.opacity(0.54), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            }

            HStack(spacing: 12) {
                PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                    Label("Upload picture", systemImage: "photo.fill.on.rectangle.fill")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(Color.black.opacity(0.82))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 15)
                        .background(Color.white.opacity(0.56), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                }
                .buttonStyle(.plain)

                Button {
                    photoData = nil
                    selectedPhotoItem = nil
                } label: {
                    Label("Remove", systemImage: "trash")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(Color.black.opacity(0.74))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 15)
                        .background(Color.white.opacity(0.34), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                }
                .buttonStyle(.plain)
            }

            HStack(spacing: 12) {
                profileFact(symbol: "sparkles", title: "Style", value: "AI-ready")
                profileFact(symbol: "checklist.checked", title: "Planner", value: "Synced")
                profileFact(symbol: "brain.head.profile", title: "Identity", value: "Personal")
            }
        }
        .padding(22)
        .background(profileEditorBackground)
        .overlay {
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .stroke(Color.white.opacity(0.34), lineWidth: 1.1)
        }
        .shadow(color: Color.cyan.opacity(0.18), radius: 22, y: 12)
    }

    private var footerNote: some View {
        Text("A sharp profile keeps your AI planner feeling personal without adding friction.")
            .font(.footnote.weight(.medium))
            .foregroundStyle(.white.opacity(0.66))
            .multilineTextAlignment(.center)
            .padding(.horizontal, 24)
    }

    private var profileEditorBackground: some View {
        LinearGradient(
            colors: [
                Color(red: 0.96, green: 0.98, blue: 1.0),
                Color(red: 0.76, green: 0.95, blue: 0.98),
                Color(red: 0.91, green: 0.96, blue: 1.0),
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func profileFact(symbol: String, title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: symbol)
                .font(.callout.weight(.bold))
                .foregroundStyle(Color.cyan.opacity(0.88))

            Text(value)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(Color.black.opacity(0.82))

            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.black.opacity(0.56))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 14)
        .padding(.vertical, 14)
        .background(Color.white.opacity(0.42), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private func saveProfile() {
        guard !trimmedName.isEmpty else { return }
        store.updateProfile(name: trimmedName, photoData: photoData)
        dismiss()
    }
}

struct ProfileAvatarView: View {
    let name: String
    let photoData: Data?
    let size: CGFloat
    let accentColor: Color

    var body: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [
                            accentColor.opacity(0.96),
                            Color.white.opacity(0.96),
                            Color.blue.opacity(0.84),
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay {
                    Circle()
                        .stroke(Color.white.opacity(0.34), lineWidth: 2)
                }

            if let image {
                profileImageView(image)
            } else {
                VStack(spacing: max(size * 0.04, 4)) {
                    Image(systemName: "brain.head.profile")
                        .font(.system(size: size * 0.28, weight: .black))
                        .foregroundStyle(Color.black.opacity(0.82))

                    Text(initials)
                        .font(.system(size: size * 0.22, weight: .black, design: .rounded))
                        .foregroundStyle(Color.black.opacity(0.82))
                }
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .shadow(color: accentColor.opacity(0.24), radius: 20, y: 10)
    }

    @ViewBuilder
    private func profileImageView(_ image: PlatformImage) -> some View {
        #if canImport(UIKit)
        Image(uiImage: image)
            .resizable()
            .scaledToFill()
        #elseif canImport(AppKit)
        Image(nsImage: image)
            .resizable()
            .scaledToFill()
        #endif
    }

    private var image: PlatformImage? {
        guard let photoData else { return nil }
        return PlatformImage(data: photoData)
    }

    private var initials: String {
        let parts = name
            .split(separator: " ")
            .prefix(2)
            .compactMap { $0.first }

        let result = String(parts)
        return result.isEmpty ? "AI" : result.uppercased()
    }
}
