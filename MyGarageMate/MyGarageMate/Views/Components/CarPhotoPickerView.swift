import CoreTransferable
import PhotosUI
import SwiftUI
import UIKit
import UniformTypeIdentifiers

struct CarPhotoPickerView: View {
    @Binding var imageData: Data?
    var title: String = "Photo"
    var systemImage: String = "car.side.fill"

    @State private var selectedItem: PhotosPickerItem?
    @State private var isLoadingImage = false
    @State private var imageErrorMessage: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)

            PhotosPicker(selection: $selectedItem, matching: .images) {
                ZStack {
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(.thinMaterial)
                        .frame(height: 210)

                    if isLoadingImage {
                        VStack(spacing: 12) {
                            ProgressView()
                            Text("Preparing image")
                                .font(.headline)
                            Text("Your photo will appear here before you continue.")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                    } else if let imageData, let uiImage = UIImage(data: imageData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                            .frame(height: 210)
                            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))

                        LinearGradient(
                            colors: [.clear, .black.opacity(0.45)],
                            startPoint: .center,
                            endPoint: .bottom
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))

                        VStack {
                            Spacer()
                            HStack {
                                Label("Photo selected", systemImage: "checkmark.circle.fill")
                                    .font(.subheadline.weight(.semibold))
                                Spacer()
                                Text("Change")
                                    .font(.subheadline.weight(.semibold))
                            }
                            .foregroundStyle(.white)
                            .padding(14)
                        }
                    } else {
                        VStack(spacing: 10) {
                            Image(systemName: systemImage)
                                .font(.system(size: 38, weight: .semibold))
                                .symbolRenderingMode(.hierarchical)
                            Text("Choose Image")
                                .font(.headline)
                            Text("Stored locally as compressed JPEG data")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .overlay(alignment: .bottomTrailing) {
                    Image(systemName: "photo.badge.plus")
                        .font(.title3.weight(.semibold))
                        .padding(10)
                        .background(.ultraThinMaterial, in: Circle())
                        .padding(12)
                }
                .animation(.snappy(duration: 0.22), value: imageData)
                .animation(.snappy(duration: 0.18), value: isLoadingImage)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Choose \(title.lowercased())")

            if let imageErrorMessage {
                Text(imageErrorMessage)
                    .font(.footnote)
                    .foregroundStyle(.red)
                    .accessibilityLabel(imageErrorMessage)
            }
        }
        .onChange(of: selectedItem) { _, newValue in
            Task {
                guard let newValue else {
                    await MainActor.run {
                        isLoadingImage = false
                        imageErrorMessage = nil
                    }
                    return
                }

                await MainActor.run {
                    isLoadingImage = true
                    imageErrorMessage = nil
                }

                guard
                    let photo = try? await newValue.loadTransferable(type: PickedPhoto.self),
                    let image = UIImage(data: photo.data),
                    let jpegData = image.jpegData(compressionQuality: 0.82)
                else {
                    await MainActor.run {
                        isLoadingImage = false
                        imageErrorMessage = "Could not load that photo. Please try another image."
                        HapticsManager.warning()
                    }
                    return
                }

                await MainActor.run {
                    withAnimation(.snappy(duration: 0.22)) {
                        imageData = jpegData
                        isLoadingImage = false
                    }
                    HapticsManager.lightTap()
                }
            }
        }
    }
}

private struct PickedPhoto: Transferable {
    let data: Data

    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(importedContentType: .image) { data in
            PickedPhoto(data: data)
        }
    }
}
