import SwiftUI
import SwiftData

struct HomeView: View {
    @Binding var tab: AppTab

    @Environment(PhotoLibraryService.self) private var library
    @Query(sort: \SavedShot.addedAt, order: .reverse) private var saved: [SavedShot]
    @State private var viewing: ShotRef?
    @Namespace private var zoom

    private var greeting: String {
        switch Calendar.current.component(.hour, from: .now) {
        case 5..<12: "Good morning"
        case 12..<18: "Good afternoon"
        default: "Good evening"
        }
    }

    private var recent: [ShotRef] { library.screenshots.prefix(12).map(ShotRef.asset) }

    private var sortedIDs: Set<String> { Set(saved.compactMap(\.sourceAssetID)) }
    private var unsortedCount: Int { library.screenshots.filter { !sortedIDs.contains($0.localIdentifier) }.count }
    private var todayCount: Int { library.screenshots.filter { $0.creationDate.map(Calendar.current.isDateInToday) ?? false }.count }
    private var weekCount: Int {
        let start = Calendar.current.date(byAdding: .day, value: -7, to: .now) ?? .now
        return library.screenshots.filter { ($0.creationDate ?? .distantPast) > start }.count
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(Date.now.formatted(.dateTime.weekday(.wide).month().day()).uppercased())
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                        Text(greeting)
                            .font(.system(size: 34, weight: .bold, design: .rounded))
                    }
                    .padding(.top, 8)

                    hero
                    stats
                    recentStrip
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
            }
            .background { CanvasBackground() }
            .toolbar(.hidden, for: .navigationBar)
            .fullScreenCover(item: $viewing) { ref in
                ShotViewer(items: recent, start: ref)
                    .navigationTransition(.zoom(sourceID: ref.id, in: zoom))
            }
        }
    }

    @ViewBuilder
    private var hero: some View {
        if let latest = library.screenshots.first {
            let ref = ShotRef.asset(latest)
            Button { viewing = ref } label: {
                ZStack(alignment: .bottomLeading) {
                    ThumbView(source: .asset(latest), maxPoints: 500)
                        .frame(height: 300)
                        .frame(maxWidth: .infinity)
                    LinearGradient(colors: [.clear, .black.opacity(0.45)], startPoint: .center, endPoint: .bottom)
                    HStack(alignment: .bottom) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Latest screenshot")
                                .font(.headline)
                            Text(latest.creationDate?.relativeLabel ?? "")
                                .font(.subheadline)
                                .opacity(0.85)
                        }
                        .foregroundStyle(.white)
                        Spacer()
                        Button {
                            tab = .explore
                        } label: {
                            Label("Sort", systemImage: "wand.and.stars")
                                .font(.subheadline.weight(.semibold))
                                .padding(.horizontal, 6)
                        }
                        .buttonStyle(.glass)
                    }
                    .padding(18)
                }
                .clipShape(.rect(cornerRadius: 30, style: .continuous))
                .matchedTransitionSource(id: ref.id, in: zoom)
                .shadow(color: .black.opacity(0.12), radius: 18, y: 10)
            }
            .buttonStyle(.plain)
        } else if !library.isAuthorized {
            PhotoAccessCard()
        } else {
            VStack(spacing: 10) {
                Image(systemName: "camera.viewfinder")
                    .font(.system(size: 44))
                    .foregroundStyle(.secondary)
                Text("Take a screenshot")
                    .font(.headline)
                Text("Press the side button and volume up together. It will land in Recent right away.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(28)
            .frame(maxWidth: .infinity)
            .cardSurface()
        }
    }

    private var stats: some View {
        Grid(horizontalSpacing: 12, verticalSpacing: 12) {
            GridRow {
                StatTile(value: todayCount, label: "Today", symbol: "sun.max", tint: .orange)
                StatTile(value: weekCount, label: "This week", symbol: "calendar", tint: .blue)
            }
            GridRow {
                StatTile(value: saved.count, label: "In albums", symbol: "folder", tint: .green)
                Button { tab = .explore } label: {
                    StatTile(value: unsortedCount, label: "To sort", symbol: "tray.full", tint: .purple)
                }
                .buttonStyle(.plain)
            }
        }
    }

    @ViewBuilder
    private var recentStrip: some View {
        if !recent.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Recent")
                        .font(.title3.weight(.bold))
                    Spacer()
                    Button("See All") { tab = .albums }
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.secondary)
                }
                ScrollView(.horizontal) {
                    HStack(spacing: 10) {
                        ForEach(recent.dropFirst()) { ref in
                            Button { viewing = ref } label: {
                                ThumbView(source: ref.thumb, maxPoints: 200)
                                    .frame(width: 96, height: 200)
                                    .clipShape(.rect(cornerRadius: 16, style: .continuous))
                                    .matchedTransitionSource(id: ref.id, in: zoom)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .scrollTargetLayout()
                }
                .scrollTargetBehavior(.viewAligned)
                .scrollIndicators(.hidden)
                .scrollClipDisabled()
            }
        }
    }
}

private struct StatTile: View {
    let value: Int
    let label: String
    let symbol: String
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: symbol)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(tint)
                .frame(width: 32, height: 32)
                .background(tint.opacity(0.14), in: .circle)
            VStack(alignment: .leading, spacing: 0) {
                Text(value, format: .number)
                    .font(.system(.title, design: .rounded).weight(.bold))
                    .contentTransition(.numericText())
                Text(label)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .cardSurface(radius: 22)
    }
}
