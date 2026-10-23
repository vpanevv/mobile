import SwiftUI
import SwiftData

/// Full-screen pager with pinch-to-zoom and a floating Liquid Glass toolbar.
struct ShotViewer: View {
    let items: [ShotRef]

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Environment(PhotoLibraryService.self) private var library

    @State private var selection: String
    @State private var currentImage: UIImage?
    @State private var chromeHidden = false
    @State private var confirmDelete = false
    @State private var filedTo: Album?

    init(items: [ShotRef], start: ShotRef) {
        self.items = items.contains(start) ? items : [start]
        _selection = State(initialValue: start.id)
    }

    private var current: ShotRef? { items.first { $0.id == selection } }

    var body: some View {
        TabView(selection: $selection) {
            ForEach(items) { ref in
                ZoomableImage(source: ref.thumb) { image in
                    if ref.id == selection { currentImage = image }
                } onTap: {
                    withAnimation(.smooth) { chromeHidden.toggle() }
                }
                .tag(ref.id)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .background(Color.black)
        .ignoresSafeArea()
        .overlay(alignment: .top) { if !chromeHidden { topBar.transition(.move(edge: .top).combined(with: .opacity)) } }
        .overlay(alignment: .bottom) { if !chromeHidden { bottomBar.transition(.move(edge: .bottom).combined(with: .opacity)) } }
        .overlay {
            if let filedTo {
                Label("Added to \(filedTo.title)", systemImage: filedTo.symbol)
                    .font(.headline)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 14)
                    .glassEffect(.regular.tint(filedTo.tint.opacity(0.4)), in: .capsule)
                    .transition(.scale(scale: 0.6).combined(with: .opacity))
            }
        }
        .statusBarHidden(chromeHidden)
        .preferredColorScheme(.dark)
        .onChange(of: selection) { currentImage = nil }
        .confirmationDialog("Delete Screenshot?", isPresented: $confirmDelete, titleVisibility: .visible) {
            Button("Delete", role: .destructive) { Task { await deleteCurrent() } }
        } message: {
            Text(isSaved ? "It will be removed from this album." : "It will be moved to Recently Deleted in Photos.")
        }
    }

    private var isSaved: Bool {
        if case .saved = current { true } else { false }
    }

    private var topBar: some View {
        HStack {
            GlassCircleButton(systemImage: "xmark") { dismiss() }
            Spacer()
            if let date = current?.date {
                Text(date.relativeLabel)
                    .font(.subheadline.weight(.semibold))
                    .padding(.horizontal, 16)
                    .frame(height: 44)
                    .glassEffect(.regular, in: .capsule)
            }
            Spacer()
            Color.clear.frame(width: 44, height: 44)
        }
        .padding(.horizontal, 16)
    }

    private var bottomBar: some View {
        GlassEffectContainer(spacing: 14) {
            HStack(spacing: 14) {
                if let currentImage {
                    ShareLink(item: Image(uiImage: currentImage), preview: SharePreview("Screenshot", image: Image(uiImage: currentImage))) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 18, weight: .semibold))
                            .frame(width: 52, height: 52)
                    }
                    .glassEffect(.regular.interactive(), in: .circle)
                }

                Menu {
                    ForEach(Album.userAlbums) { album in
                        Button(album.title, systemImage: album.symbol) { file(into: album) }
                    }
                } label: {
                    Label("Add to Album", systemImage: "folder.badge.plus")
                        .font(.headline)
                        .padding(.horizontal, 20)
                        .frame(height: 52)
                }
                .glassEffect(.regular.interactive(), in: .capsule)

                if case .saved(let shot) = current {
                    Button {
                        shot.isFavorite.toggle()
                    } label: {
                        Image(systemName: shot.isFavorite ? "heart.fill" : "heart")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(shot.isFavorite ? .pink : .primary)
                            .contentTransition(.symbolEffect(.replace))
                            .frame(width: 52, height: 52)
                    }
                    .buttonStyle(.plain)
                    .glassEffect(.regular.interactive(), in: .circle)
                }

                Button {
                    confirmDelete = true
                } label: {
                    Image(systemName: "trash")
                        .font(.system(size: 18, weight: .semibold))
                        .frame(width: 52, height: 52)
                }
                .buttonStyle(.plain)
                .glassEffect(.regular.interactive(), in: .circle)
            }
        }
        .padding(.bottom, 8)
    }

    private func file(into album: Album) {
        guard let current else { return }
        Task {
            await ShotActions.file(current, into: album, context: context, library: library)
            withAnimation(.spring(duration: 0.4, bounce: 0.4)) { filedTo = album }
            try? await Task.sleep(for: .seconds(1.3))
            withAnimation(.smooth) { filedTo = nil }
        }
    }

    private func deleteCurrent() async {
        switch current {
        case .saved(let shot):
            dismiss()
            ShotActions.remove(shot, context: context)
        case .asset(let asset):
            do {
                try await library.deleteFromLibrary(asset)
                dismiss()
            } catch {}
        case nil:
            break
        }
    }
}

private struct ZoomableImage: View {
    let source: ThumbSource
    let onLoad: (UIImage) -> Void
    let onTap: () -> Void

    @State private var scale: CGFloat = 1
    @State private var lastScale: CGFloat = 1
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero

    var body: some View {
        FullImage(source: source, onLoad: onLoad)
            .scaleEffect(scale)
            .offset(offset)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .contentShape(.rect)
            .gesture(
                MagnifyGesture()
                    .onChanged { scale = max(1, min(5, lastScale * $0.magnification)) }
                    .onEnded { _ in
                        lastScale = scale
                        if scale <= 1 { reset() }
                    }
            )
            .gesture(
                DragGesture()
                    .onChanged { offset = CGSize(width: lastOffset.width + $0.translation.width,
                                                 height: lastOffset.height + $0.translation.height) }
                    .onEnded { _ in lastOffset = offset },
                isEnabled: scale > 1
            )
            .onTapGesture(count: 2) {
                withAnimation(.spring(duration: 0.35)) {
                    if scale > 1 { reset() } else { scale = 2.5; lastScale = 2.5 }
                }
            }
            .onTapGesture(perform: onTap)
    }

    private func reset() {
        withAnimation(.spring(duration: 0.35)) {
            scale = 1; lastScale = 1; offset = .zero; lastOffset = .zero
        }
    }
}
