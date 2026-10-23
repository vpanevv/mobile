import SwiftUI
import SwiftData
import PhotosUI

struct AlbumDetailView: View {
    let album: Album

    @Environment(PhotoLibraryService.self) private var library
    @Environment(\.modelContext) private var context
    @Query private var saved: [SavedShot]

    @State private var viewing: ShotRef?
    @State private var pickerFilter: PHPickerFilter?
    @State private var pickerItems: [PhotosPickerItem] = []
    @State private var isImporting = false
    @State private var showRecentPicker = false
    @Namespace private var zoom

    init(album: Album) {
        self.album = album
        let raw = album.rawValue
        _saved = Query(filter: #Predicate<SavedShot> { $0.albumRaw == raw },
                       sort: \SavedShot.addedAt, order: .reverse)
    }

    private var shots: [ShotRef] {
        album.isLibraryBacked ? library.screenshots.map(ShotRef.asset) : saved.map(ShotRef.saved)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                summary
                if album.isLibraryBacked && !library.isAuthorized {
                    PhotoAccessCard()
                } else if shots.isEmpty {
                    emptyState
                } else {
                    ShotGrid(shots: shots, namespace: zoom) { viewing = $0 }
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 24)
        }
        .background { CanvasBackground() }
        .navigationTitle(album.title)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            if !album.isLibraryBacked {
                ToolbarItem(placement: .topBarTrailing) {
                    addMenu
                }
            }
        }
        .overlay(alignment: .bottom) {
            if isImporting {
                Label("Importing…", systemImage: "arrow.down.circle")
                    .font(.subheadline.weight(.medium))
                    .padding(.horizontal, 18)
                    .padding(.vertical, 12)
                    .glassEffect(.regular, in: .capsule)
                    .padding(.bottom, 12)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .fullScreenCover(item: $viewing) { ref in
            ShotViewer(items: shots, start: ref)
                .navigationTransition(.zoom(sourceID: ref.id, in: zoom))
        }
        .sheet(isPresented: $showRecentPicker) {
            RecentPickerSheet(album: album)
        }
        .photosPicker(
            isPresented: Binding(get: { pickerFilter != nil }, set: { if !$0 { pickerFilter = nil } }),
            selection: $pickerItems,
            maxSelectionCount: 50,
            matching: pickerFilter ?? .images,
            photoLibrary: .shared()
        )
        .onChange(of: pickerItems) { _, items in
            guard !items.isEmpty else { return }
            pickerItems = []
            Task {
                withAnimation { isImporting = true }
                await ShotActions.importItems(items, into: album, context: context)
                withAnimation { isImporting = false }
            }
        }
    }

    private var summary: some View {
        HStack(spacing: 8) {
            Image(systemName: album.symbol)
                .foregroundStyle(album.tint)
            Text("\(shots.count) screenshots")
                .contentTransition(.numericText())
            if album.isLibraryBacked {
                Text("·")
                Text("Updates automatically")
            }
        }
        .font(.subheadline)
        .foregroundStyle(.secondary)
    }

    private var addMenu: some View {
        Menu {
            Button("From Recent Screenshots", systemImage: "photo.on.rectangle") { showRecentPicker = true }
            Button("Screenshots in Photos", systemImage: "camera.viewfinder") { pickerFilter = .screenshots }
            Button("Any Image", systemImage: "photo") { pickerFilter = .images }
        } label: {
            Label("Add", systemImage: "plus")
        }
    }

    private var emptyState: some View {
        VStack(spacing: 18) {
            FannedStack(album: album, thumbs: [])
                .frame(height: 170)
            VStack(spacing: 6) {
                Text("No screenshots yet")
                    .font(.title3.weight(.semibold))
                Text("Add images to keep your \(album.title.lowercased()) screenshots in one place.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            GlassEffectContainer(spacing: 12) {
                VStack(spacing: 12) {
                    Button {
                        showRecentPicker = true
                    } label: {
                        Label("Add from Recent", systemImage: "photo.on.rectangle")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 6)
                    }
                    .buttonStyle(.glassProminent)

                    Button {
                        pickerFilter = .images
                    } label: {
                        Label("Choose from Photos", systemImage: "photo")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 6)
                    }
                    .buttonStyle(.glass)
                }
            }
            .padding(.horizontal, 24)
        }
        .padding(.vertical, 40)
        .frame(maxWidth: .infinity)
    }
}

/// Explains and requests Photos access, which "Recent" needs.
struct PhotoAccessCard: View {
    @Environment(PhotoLibraryService.self) private var library
    @Environment(\.openURL) private var openURL

    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: "photo.badge.checkmark")
                .font(.system(size: 40))
                .foregroundStyle(.indigo)
                .symbolEffect(.pulse)
            Text("Allow Photos Access")
                .font(.title3.weight(.semibold))
            Text("New screenshots appear in Recent automatically once Screenshot Manager can read your library.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button {
                if library.status == .notDetermined {
                    Task { await library.bootstrap() }
                } else if let url = URL(string: UIApplication.openSettingsURLString) {
                    openURL(url)
                }
            } label: {
                Text(library.status == .notDetermined ? "Allow Access" : "Open Settings")
                    .font(.headline)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
            }
            .buttonStyle(.glassProminent)
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .cardSurface()
    }
}

/// Multi-select sheet for filing screenshots from Recent into an album.
struct RecentPickerSheet: View {
    let album: Album

    @Environment(PhotoLibraryService.self) private var library
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @State private var selection: Set<String> = []
    @State private var isSaving = false

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 6), count: 4)

    var body: some View {
        NavigationStack {
            Group {
                if !library.isAuthorized {
                    PhotoAccessCard().padding()
                } else if library.screenshots.isEmpty {
                    ContentUnavailableView("No Screenshots", systemImage: "camera.viewfinder",
                                           description: Text("Take a screenshot and it will show up here."))
                } else {
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 6) {
                            ForEach(library.screenshots, id: \.localIdentifier) { asset in
                                let isSelected = selection.contains(asset.localIdentifier)
                                ThumbView(source: .asset(asset), maxPoints: 160)
                                    .aspectRatio(0.48, contentMode: .fit)
                                    .clipShape(.rect(cornerRadius: 10, style: .continuous))
                                    .overlay {
                                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                                            .strokeBorder(album.tint, lineWidth: isSelected ? 3 : 0)
                                    }
                                    .overlay(alignment: .bottomTrailing) {
                                        Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                                            .font(.title3)
                                            .foregroundStyle(isSelected ? AnyShapeStyle(album.tint) : AnyShapeStyle(.white))
                                            .background(Circle().fill(isSelected ? .white : .black.opacity(0.2)).padding(2))
                                            .padding(6)
                                            .contentTransition(.symbolEffect(.replace))
                                    }
                                    .onTapGesture {
                                        if isSelected { selection.remove(asset.localIdentifier) }
                                        else { selection.insert(asset.localIdentifier) }
                                    }
                            }
                        }
                        .padding(8)
                    }
                }
            }
            .navigationTitle("Add to \(album.title)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", systemImage: "xmark", role: .cancel) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(role: .confirm) {
                        Task { await save() }
                    } label: {
                        if isSaving { ProgressView() } else { Label("Add \(selection.count)", systemImage: "checkmark") }
                    }
                    .disabled(selection.isEmpty || isSaving)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationBackground(.thinMaterial)
    }

    private func save() async {
        isSaving = true
        let assets = library.screenshots.filter { selection.contains($0.localIdentifier) }
        for asset in assets {
            await ShotActions.file(.asset(asset), into: album, context: context, library: library)
        }
        dismiss()
    }
}
