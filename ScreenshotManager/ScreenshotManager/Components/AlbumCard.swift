import SwiftUI

/// Album tile: a fanned stack of the album's latest screenshots, a glass
/// icon badge, the title and the item count.
struct AlbumCard: View {
    let album: Album
    let thumbs: [ThumbSource]
    let count: Int
    var onAddImages: (() -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            FannedStack(album: album, thumbs: thumbs)
                .frame(height: 158)
                .frame(maxWidth: .infinity)
                .overlay(alignment: .bottomLeading) {
                    Image(systemName: album.symbol)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.primary)
                        .frame(width: 28, height: 28)
                        .glassEffect(.regular, in: .rect(cornerRadius: 9, style: .continuous))
                        .offset(x: -2, y: 4)
                }

            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(album.title)
                        .font(.system(.headline, design: .rounded))
                        .foregroundStyle(.primary)
                    Text(count, format: .number)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .contentTransition(.numericText())
                }
                Spacer()
                Menu {
                    if let onAddImages {
                        Button("Add Images", systemImage: "plus", action: onAddImages)
                    }
                    Label("\(count) screenshots", systemImage: album.symbol)
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .frame(width: 30, height: 24)
                        .contentShape(.rect)
                }
            }
        }
        .padding(14)
        .cardSurface()
    }
}

/// Up to three screenshots fanned out like the reference design. Falls back
/// to tinted placeholder cards when the album is empty.
struct FannedStack: View {
    let album: Album
    let thumbs: [ThumbSource]

    private let cardHeight: CGFloat = 132

    var body: some View {
        ZStack {
            // Back to front.
            ForEach(Array(layers.enumerated()), id: \.offset) { index, layer in
                card(for: layer.thumb)
                    .frame(width: cardHeight * 0.62, height: cardHeight)
                    .scaleEffect(layer.scale)
                    .rotationEffect(.degrees(layer.angle))
                    .offset(x: layer.x, y: layer.y)
                    .shadow(color: .black.opacity(index == layers.count - 1 ? 0.22 : 0.12), radius: 8, x: 2, y: 6)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private struct Layer { let thumb: ThumbSource?; let angle: Double; let x: CGFloat; let y: CGFloat; let scale: CGFloat }

    private var layers: [Layer] {
        let slots: [ThumbSource?] = thumbs.isEmpty ? [nil, nil, nil] : Array(thumbs.prefix(3)).map(Optional.some)
        let geometry: [(Double, CGFloat, CGFloat, CGFloat)] = [
            (-4, -6, 0, 1.0),   // front
            (7, 26, -4, 0.88),  // middle
            (-12, -34, 2, 0.8), // back
        ]
        return slots.enumerated()
            .map { index, thumb in
                let g = geometry[index]
                return Layer(thumb: thumb, angle: g.0, x: g.1, y: g.2, scale: g.3)
            }
            .reversed()
    }

    @ViewBuilder
    private func card(for thumb: ThumbSource?) -> some View {
        let shape = RoundedRectangle(cornerRadius: 12, style: .continuous)
        Group {
            if let thumb {
                ThumbView(source: thumb, maxPoints: 160)
            } else {
                LinearGradient(colors: [album.tint.opacity(0.35), album.tint.opacity(0.12)],
                               startPoint: .topLeading, endPoint: .bottomTrailing)
                    .overlay {
                        Image(systemName: album.symbol)
                            .font(.title3)
                            .foregroundStyle(album.tint.opacity(0.7))
                    }
                    .background(Color.card)
            }
        }
        .clipShape(shape)
        .overlay(shape.strokeBorder(.white.opacity(0.7), lineWidth: 2))
    }
}
