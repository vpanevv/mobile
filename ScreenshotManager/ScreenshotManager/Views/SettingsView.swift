import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(PhotoLibraryService.self) private var library
    @Environment(\.modelContext) private var context
    @Environment(\.openURL) private var openURL
    @Query private var saved: [SavedShot]
    @AppStorage("showCaptureToast") private var showCaptureToast = true
    @State private var confirmClear = false
    @State private var storage: Int64 = 0

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack(spacing: 14) {
                        Image(systemName: "photo.stack.fill")
                            .font(.title2)
                            .foregroundStyle(.white)
                            .frame(width: 52, height: 52)
                            .background(LinearGradient(colors: [.indigo, .purple], startPoint: .topLeading, endPoint: .bottomTrailing),
                                        in: .rect(cornerRadius: 14, style: .continuous))
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Screenshot Manager")
                                .font(.headline)
                            Text("\(library.screenshots.count) screenshots · \(saved.count) in albums")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }

                Section {
                    LabeledContent("Photos Access") {
                        Text(accessLabel).foregroundStyle(library.isAuthorized ? .green : .orange)
                    }
                    Button("Manage in Settings", systemImage: "gear") {
                        if let url = URL(string: UIApplication.openSettingsURLString) { openURL(url) }
                    }
                    Toggle("Capture Banner", systemImage: "bell.badge", isOn: $showCaptureToast)
                } header: {
                    Text("Recent")
                } footer: {
                    Text("Every screenshot you take is saved to Photos. Recent mirrors them live, and shows a banner when you capture one while the app is open.")
                }

                Section("Albums") {
                    ForEach(Album.userAlbums) { album in
                        LabeledContent {
                            Text(saved.filter { $0.albumRaw == album.rawValue }.count, format: .number)
                        } label: {
                            Label(album.title, systemImage: album.symbol)
                                .foregroundStyle(.primary)
                                .tint(album.tint)
                        }
                    }
                    LabeledContent("Storage Used", value: ByteCountFormatter.string(fromByteCount: storage, countStyle: .file))
                }

                Section {
                    Button("Clear All Albums", systemImage: "trash", role: .destructive) { confirmClear = true }
                        .disabled(saved.isEmpty)
                } footer: {
                    Text("Removes images from your albums. Screenshots in Photos are not affected.")
                }
            }
            .scrollContentBackground(.hidden)
            .background { CanvasBackground() }
            .navigationTitle("Settings")
            .task(id: saved.count) { storage = ImageStore.bytesUsed }
            .confirmationDialog("Clear all albums?", isPresented: $confirmClear, titleVisibility: .visible) {
                Button("Clear \(saved.count) Images", role: .destructive) {
                    for shot in saved { ShotActions.remove(shot, context: context) }
                }
            }
        }
    }

    private var accessLabel: String {
        switch library.status {
        case .authorized: "Full"
        case .limited: "Limited"
        case .denied, .restricted: "Denied"
        default: "Not Set"
        }
    }
}
