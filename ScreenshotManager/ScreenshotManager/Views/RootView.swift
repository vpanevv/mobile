import SwiftUI

enum AppTab: Hashable {
    case home, albums, explore, settings
}

struct RootView: View {
    @Environment(PhotoLibraryService.self) private var library
    @Environment(\.scenePhase) private var scenePhase
    @AppStorage("showCaptureToast") private var showCaptureToast = true
    @State private var tab: AppTab = .albums
    @State private var toastVisible = false

    var body: some View {
        TabView(selection: $tab) {
            Tab("Home", systemImage: "house", value: .home) {
                HomeView(tab: $tab)
            }
            Tab("Albums", systemImage: "folder.fill", value: .albums) {
                AlbumsView()
            }
            Tab("Explore", systemImage: "safari", value: .explore) {
                ExploreView()
            }
            Tab("Settings", systemImage: "gearshape", value: .settings) {
                SettingsView()
            }
        }
        .tabBarMinimizeBehavior(.onScrollDown)
        .tint(.primary)
        .overlay(alignment: .top) {
            if toastVisible {
                CaptureToast()
                    .transition(.move(edge: .top).combined(with: .opacity).combined(with: .scale(scale: 0.8)))
                    .onTapGesture {
                        tab = .albums
                        withAnimation { toastVisible = false }
                    }
            }
        }
        .task { await library.bootstrap() }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { library.refreshStatus() }
        }
        .onChange(of: library.captureCount) {
            guard showCaptureToast else { return }
            Task {
                // Give Photos a moment to write the new screenshot.
                try? await Task.sleep(for: .seconds(1.2))
                withAnimation(.spring(duration: 0.5, bounce: 0.35)) { toastVisible = true }
                try? await Task.sleep(for: .seconds(3.5))
                withAnimation(.smooth) { toastVisible = false }
            }
        }
    }
}

/// Liquid Glass banner shown when a screenshot is taken while the app is open.
private struct CaptureToast: View {
    @Environment(PhotoLibraryService.self) private var library

    var body: some View {
        HStack(spacing: 12) {
            Group {
                if let latest = library.screenshots.first {
                    ThumbView(source: .asset(latest), maxPoints: 80)
                } else {
                    Image(systemName: "camera.viewfinder")
                        .font(.title3)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .frame(width: 34, height: 48)
            .clipShape(.rect(cornerRadius: 8, style: .continuous))

            VStack(alignment: .leading, spacing: 1) {
                Text("Screenshot saved")
                    .font(.subheadline.weight(.semibold))
                Text("Added to Recent")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 8)
            Image(systemName: "checkmark.circle.fill")
                .font(.title3)
                .foregroundStyle(.green)
                .symbolEffect(.bounce, value: library.captureCount)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .frame(maxWidth: 320)
        .glassEffect(.regular.interactive(), in: .capsule)
        .padding(.top, 6)
    }
}
