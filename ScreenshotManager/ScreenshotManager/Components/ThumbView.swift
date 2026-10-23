import SwiftUI

/// Loads and displays a screenshot from Photos or from the album store,
/// filling its frame.
struct ThumbView: View {
    let source: ThumbSource
    /// Longest side, in points, the image will be shown at.
    var maxPoints: CGFloat = 260
    var contentMode: ContentMode = .fill

    @Environment(PhotoLibraryService.self) private var library
    @Environment(\.displayScale) private var displayScale
    @State private var image: UIImage?

    var body: some View {
        Rectangle()
            .fill(Color.thumbFill)
            .overlay {
                if let image {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: contentMode)
                        .transition(.opacity)
                }
            }
            .clipped()
            .task(id: source.key) {
                let pixels = maxPoints * displayScale
                let loaded: UIImage? = switch source {
                case .asset(let asset):
                    await library.image(for: asset, targetSize: CGSize(width: pixels, height: pixels))
                case .file(let name):
                    await ImageStore.thumbnail(for: name, maxPixel: pixels)
                }
                withAnimation(.easeOut(duration: 0.2)) { image = loaded }
            }
    }
}

/// Full-resolution image for the viewer, sized to fit.
struct FullImage: View {
    let source: ThumbSource
    var onLoad: (UIImage) -> Void = { _ in }

    @Environment(PhotoLibraryService.self) private var library
    @State private var image: UIImage?

    var body: some View {
        Group {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
            } else {
                ProgressView().tint(.white)
            }
        }
        .task(id: source.key) {
            let loaded: UIImage? = switch source {
            case .asset(let asset):
                await library.image(for: asset, targetSize: CGSize(width: 2400, height: 2400), contentMode: .aspectFit)
            case .file(let name):
                await ImageStore.thumbnail(for: name, maxPixel: 3000)
            }
            image = loaded
            if let loaded { onLoad(loaded) }
        }
    }
}
