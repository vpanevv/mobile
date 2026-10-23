import SwiftUI
import SwiftData
import PhotosUI

struct AlbumsView: View {
    @Environment(PhotoLibraryService.self) private var library
    @Environment(\.modelContext) private var context
    @Query(sort: \SavedShot.addedAt, order: .reverse) private var saved: [SavedShot]

    @State private var query = ""
    @State private var sort: AlbumSort = .all
    @State private var path: [Album] = []
    @State private var viewing: ShotRef?
    @State private var pickerAlbum: Album?
    @State private var pickerItems: [PhotosPickerItem] = []
    @FocusState private var searchFocused: Bool
    @Namespace private var zoom

    private let columns = [GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14)]

    var body: some View {
        NavigationStack(path: $path) {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    header
                    searchField
                    if query.isEmpty {
                        albumGrid
                    } else {
                        searchResults
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
            }
            .scrollDismissesKeyboard(.immediately)
            .background { CanvasBackground() }
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: Album.self) { album in
                AlbumDetailView(album: album)
                    .navigationTransition(.zoom(sourceID: album, in: zoom))
            }
            .fullScreenCover(item: $viewing) { ref in
                ShotViewer(items: searchMatches.map(ShotRef.saved), start: ref)
                    .navigationTransition(.zoom(sourceID: ref.id, in: zoom))
            }
            .photosPicker(
                isPresented: Binding(get: { pickerAlbum != nil }, set: { if !$0 { pickerAlbum = nil } }),
                selection: $pickerItems,
                maxSelectionCount: 50,
                matching: .images,
                photoLibrary: .shared()
            )
            .onChange(of: pickerItems) { _, items in
                guard !items.isEmpty, let album = pickerAlbum else { return }
                pickerItems = []
                Task { await ShotActions.importItems(items, into: album, context: context) }
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .top) {
                Text("Screenshot\nManager")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .fixedSize(horizontal: false, vertical: true)
                Spacer()
                GlassEffectContainer(spacing: 10) {
                    HStack(spacing: 10) {
                        Menu {
                            Picker("Sort", selection: $sort.animation(.smooth)) {
                                ForEach(AlbumSort.allCases) { option in
                                    Label(option.rawValue, systemImage: option.symbol).tag(option)
                                }
                            }
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "folder.fill")
                                Text(sort == .all ? "All" : sort == .mostItems ? "Top" : "New")
                                Image(systemName: "chevron.down")
                                    .font(.caption2.weight(.bold))
                            }
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.primary)
                            .padding(.horizontal, 14)
                            .frame(height: 44)
                            .contentShape(.capsule)
                        }
                        .glassEffect(.regular.interactive(), in: .capsule)
    
                        GlassCircleButton(systemImage: "magnifyingglass") {
                            searchFocused = true
                        }
                    }
                }
            }
            Text("All your screenshots, organized.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.top, 8)
    }

    private var searchField: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
            TextField("Search screenshots…", text: $query.animation(.smooth))
                .focused($searchFocused)
                .submitLabel(.search)
                .autocorrectionDisabled()
            if !query.isEmpty {
                Button {
                    withAnimation(.smooth) { query = "" }
                } label: {
                    Image(systemName: "xmark.circle.fill").foregroundStyle(.tertiary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 16)
        .frame(height: 48)
        .glassEffect(.regular.interactive(), in: .capsule)
    }

    // MARK: - Albums

    private var albumGrid: some View {
        LazyVGrid(columns: columns, spacing: 14) {
            ForEach(sortedAlbums) { album in
                NavigationLink(value: album) {
                    AlbumCard(
                        album: album,
                        thumbs: thumbs(for: album),
                        count: count(for: album),
                        onAddImages: album.isLibraryBacked ? nil : { pickerAlbum = album }
                    )
                    .matchedTransitionSource(id: album, in: zoom)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var sortedAlbums: [Album] {
        switch sort {
        case .all:
            Album.allCases
        case .mostItems:
            Album.allCases.sorted { count(for: $0) > count(for: $1) }
        case .updated:
            Album.allCases.sorted { lastUpdate(for: $0) > lastUpdate(for: $1) }
        }
    }

    private func shots(in album: Album) -> [SavedShot] {
        saved.filter { $0.albumRaw == album.rawValue }
    }

    private func count(for album: Album) -> Int {
        album.isLibraryBacked ? library.screenshots.count : shots(in: album).count
    }

    private func thumbs(for album: Album) -> [ThumbSource] {
        album.isLibraryBacked
            ? library.screenshots.prefix(3).map { .asset($0) }
            : shots(in: album).prefix(3).map { .file($0.fileName) }
    }

    private func lastUpdate(for album: Album) -> Date {
        album.isLibraryBacked
            ? library.screenshots.first?.creationDate ?? .distantPast
            : shots(in: album).first?.addedAt ?? .distantPast
    }

    // MARK: - Search

    private var matchingAlbums: [Album] {
        Album.allCases.filter { $0.title.localizedStandardContains(query) }
    }

    private var searchMatches: [SavedShot] {
        saved.filter {
            $0.recognizedText.localizedStandardContains(query) || $0.album.title.localizedStandardContains(query)
        }
    }

    @ViewBuilder
    private var searchResults: some View {
        if !matchingAlbums.isEmpty {
            ScrollView(.horizontal) {
                HStack(spacing: 10) {
                    ForEach(matchingAlbums) { album in
                        Button {
                            path.append(album)
                        } label: {
                            Label(album.title, systemImage: album.symbol)
                                .font(.subheadline.weight(.medium))
                                .padding(.horizontal, 14)
                                .padding(.vertical, 10)
                        }
                        .buttonStyle(.glass)
                    }
                }
            }
            .scrollIndicators(.hidden)
        }

        Text(searchMatches.isEmpty ? "No screenshots match “\(query)”" : "Text found in \(searchMatches.count) screenshots")
            .font(.footnote.weight(.semibold))
            .foregroundStyle(.secondary)
            .textCase(.uppercase)
            .padding(.top, 4)

        ShotGrid(shots: searchMatches.map(ShotRef.saved), namespace: zoom, showsAlbumBadge: true) { ref in
            searchFocused = false
            viewing = ref
        }
    }
}
