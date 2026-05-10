import PhotosUI
import SwiftUI
import UIKit

struct CarPhotoPickerView: View {
    @Binding var imageData: Data?
    var title: String = "Photo"
    var systemImage: String = "car.side.fill"

    @State private var selectedItem: PhotosPickerItem?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)

            PhotosPicker(selection: $selectedItem, matching: .images) {
                ZStack {
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(.thinMaterial)
                        .frame(height: 210)

                    if let imageData, let uiImage = UIImage(data: imageData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                            .frame(height: 210)
                            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
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
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Choose \(title.lowercased())")
        }
        .onChange(of: selectedItem) { _, newValue in
            Task {
                guard
                    let data = try? await newValue?.loadTransferable(type: Data.self),
                    let image = UIImage(data: data),
                    let jpegData = image.jpegData(compressionQuality: 0.82)
                else { return }

                await MainActor.run {
                    imageData = jpegData
                    HapticsManager.lightTap()
                }
            }
        }
    }
}
