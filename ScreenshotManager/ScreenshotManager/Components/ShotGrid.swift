import SwiftUI
import SwiftData

/// Three-column grid of screenshots with context-menu filing actions.
struct ShotGrid: View {
    let shots: [ShotRef]
    let namespace: Namespace.ID
    var showsAlbumBadge = false
    let onOpen: (ShotRef) -> Void

    @Environment(\.modelContext) private var context
    @Environment(PhotoLibraryService.self) private var library

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 3)

    var body: some View {
        LazyVGrid(columns: columns, spacing: 8) {
            ForEach(shots) { ref in
                Button { onOpen(ref) } label: {
                    ThumbView(source: ref.thumb, maxPoints: 220)
                        .aspectRatio(0.48, contentMode: .fit)
                        .clipShape(.rect(cornerRadius: 14, style: .continuous))
                        .overlay(alignment: .bottomLeading) {
                            if showsAlbumBadge, case .saved(let shot) = ref {
                                Image(systemName: shot.album.symbol)
                                    .font(.caption2.weight(.bold))
                                    .frame(width: 24, height: 24)
                                    .glassEffect(.regular, in: .circle)
                                    .padding(6)
                            }
                        }
                        .overlay(alignment: .topTrailing) {
                            if case .saved(let shot) = ref, shot.isFavorite {
                                Image(systemName: "heart.fill")
                                    .font(.caption2)
                                    .foregroundStyle(.white)
                                    .shadow(radius: 2)
                                    .padding(7)
                            }
                        }
                        .matchedTransitionSource(id: ref.id, in: namespace)
                }
                .buttonStyle(.plain)
                .contextMenu {
                    Menu("Add to Album", systemImage: "folder.badge.plus") {
                        ForEach(Album.userAlbums) { album in
                            Button(album.title, systemImage: album.symbol) {
                                Task { await ShotActions.file(ref, into: album, context: context, library: library) }
                            }
                        }
                    }
                    if case .saved(let shot) = ref {
                        Button(shot.isFavorite ? "Unfavorite" : "Favorite",
                               systemImage: shot.isFavorite ? "heart.slash" : "heart") {
                            shot.isFavorite.toggle()
                        }
                        Button("Remove from \(shot.album.title)", systemImage: "trash", role: .destructive) {
                            withAnimation { ShotActions.remove(shot, context: context) }
                        }
                    }
                } preview: {
                    ThumbView(source: ref.thumb, maxPoints: 500, contentMode: .fit)
                        .frame(width: 260, height: 540)
                }
            }
        }
    }
}
