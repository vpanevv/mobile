import SwiftUI
import SwiftData
import Photos

/// Quick-sort deck: unsorted screenshots from Recent, one at a time, filed
/// into an album with a single tap.
struct ExploreView: View {
    @Environment(PhotoLibraryService.self) private var library
    @Environment(\.modelContext) private var context
    @Query private var saved: [SavedShot]

    @State private var skipped: Set<String> = []
    @State private var leaving: [String: CGFloat] = [:]
    @State private var lastFiled: Album?
    @State private var drag: CGSize = .zero

    private var queue: [PHAsset] {
        let sorted = Set(saved.compactMap(\.sourceAssetID))
        return library.screenshots.filter {
            !sorted.contains($0.localIdentifier) && !skipped.contains($0.localIdentifier)
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                header
                if !library.isAuthorized {
                    Spacer()
                    PhotoAccessCard().padding(.horizontal, 20)
                    Spacer()
                } else if queue.isEmpty {
                    Spacer()
                    allDone
                    Spacer()
                } else {
                    deck
                    albumButtons
                }
            }
            .padding(.bottom, 12)
            .background { CanvasBackground() }
            .toolbar(.hidden, for: .navigationBar)
        }
    }

    private var header: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Quick Sort")
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                Text(queue.isEmpty ? "Everything is organized" : "\(queue.count) screenshots to sort")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .contentTransition(.numericText())
            }
            Spacer()
            if !skipped.isEmpty {
                GlassCircleButton(systemImage: "arrow.counterclockwise") {
                    withAnimation(.smooth) { skipped.removeAll() }
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
    }

    private var deck: some View {
        let visible = Array(queue.prefix(3))
        return ZStack {
            ForEach(Array(visible.enumerated().reversed()), id: \.element.localIdentifier) { index, asset in
                let isTop = index == 0
                ThumbView(source: .asset(asset), maxPoints: 520)
                    .aspectRatio(0.5, contentMode: .fit)
                    .clipShape(.rect(cornerRadius: 28, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 28, style: .continuous)
                            .strokeBorder(.white.opacity(0.6), lineWidth: 3)
                    }
                    .overlay(alignment: .top) {
                        if isTop, let date = asset.creationDate {
                            Text(date.relativeLabel)
                                .font(.caption.weight(.semibold))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 7)
                                .glassEffect(.regular, in: .capsule)
                                .padding(12)
                        }
                    }
                    .shadow(color: .black.opacity(isTop ? 0.22 : 0.08), radius: 18, y: 10)
                    .scaleEffect(1 - CGFloat(index) * 0.06)
                    .offset(y: CGFloat(index) * -18)
                    .rotationEffect(.degrees(isTop ? Double(drag.width / 18) : Double(index) * (index.isMultiple(of: 2) ? 3 : -3)))
                    .offset(isTop ? drag : .zero)
                    .offset(x: leaving[asset.localIdentifier] ?? 0)
                    .gesture(isTop ? swipe(asset) : nil)
                    .transition(.asymmetric(insertion: .scale(scale: 0.9).combined(with: .opacity), removal: .opacity))
            }
        }
        .padding(.horizontal, 60)
        .frame(maxHeight: .infinity)
    }

    private func swipe(_ asset: PHAsset) -> some Gesture {
        DragGesture()
            .onChanged { drag = $0.translation }
            .onEnded { value in
                if abs(value.translation.width) > 120 {
                    skip(asset, direction: value.translation.width > 0 ? 1 : -1)
                } else {
                    withAnimation(.spring(duration: 0.4, bounce: 0.4)) { drag = .zero }
                }
            }
    }

    private var albumButtons: some View {
        VStack(spacing: 12) {
            GlassEffectContainer(spacing: 10) {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 3), spacing: 10) {
                    ForEach(Album.userAlbums) { album in
                        Button {
                            if let top = queue.first { file(top, into: album) }
                        } label: {
                            VStack(spacing: 6) {
                                Image(systemName: album.symbol)
                                    .font(.title3)
                                    .foregroundStyle(album.tint)
                                    .symbolEffect(.bounce, value: lastFiled == album)
                                Text(album.title)
                                    .font(.footnote.weight(.semibold))
                                    .foregroundStyle(.primary)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 64)
                            .contentShape(.rect(cornerRadius: 20))
                        }
                        .buttonStyle(.plain)
                        .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 20, style: .continuous))
                    }

                    Button {
                        if let top = queue.first { skip(top, direction: 1) }
                    } label: {
                        VStack(spacing: 6) {
                            Image(systemName: "forward.fill")
                                .font(.title3)
                            Text("Skip")
                                .font(.footnote.weight(.semibold))
                        }
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 64)
                        .contentShape(.rect(cornerRadius: 20))
                    }
                    .buttonStyle(.plain)
                    .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 20, style: .continuous))
                }
            }
        }
        .padding(.horizontal, 20)
    }

    private var allDone: some View {
        VStack(spacing: 14) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 60))
                .foregroundStyle(.green.gradient)
                .symbolEffect(.bounce, value: queue.isEmpty)
            Text("All sorted")
                .font(.title2.weight(.bold))
            Text("New screenshots will show up here so you can file them in a tap.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
    }

    private func file(_ asset: PHAsset, into album: Album) {
        lastFiled = album
        fly(asset, direction: -1)
        Task { await ShotActions.file(.asset(asset), into: album, context: context, library: library) }
    }

    private func skip(_ asset: PHAsset, direction: CGFloat) {
        fly(asset, direction: direction)
        Task {
            try? await Task.sleep(for: .milliseconds(250))
            withAnimation(.smooth) { _ = skipped.insert(asset.localIdentifier) }
        }
    }

    private func fly(_ asset: PHAsset, direction: CGFloat) {
        withAnimation(.easeIn(duration: 0.25)) {
            leaving[asset.localIdentifier] = direction * 600
            drag = .zero
        }
    }
}
