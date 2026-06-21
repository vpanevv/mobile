import PhotosUI
import QuickLook
import SwiftData
import SwiftUI
import UniformTypeIdentifiers

struct PreviewDocument: Identifiable {
    let id = UUID()
    let url: URL
}

/// Wraps `QLPreviewController` so documents (PDFs, images) preview natively.
struct QuickLookPreview: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> UINavigationController {
        let controller = QLPreviewController()
        controller.dataSource = context.coordinator
        return UINavigationController(rootViewController: controller)
    }

    func updateUIViewController(_ uiViewController: UINavigationController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(url: url) }

    final class Coordinator: NSObject, QLPreviewControllerDataSource {
        let url: URL
        init(url: URL) { self.url = url }

        func numberOfPreviewItems(in controller: QLPreviewController) -> Int { 1 }

        func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
            url as NSURL
        }
    }
}

struct DocumentVaultView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var car: Car

    @State private var pendingCategory: DocumentCategory = .other
    @State private var isPickingPhoto = false
    @State private var photoItem: PhotosPickerItem?
    @State private var isImportingFile = false
    @State private var previewItem: PreviewDocument?
    @State private var documentPendingDeletion: CarDocument?
    @State private var errorMessage: String?

    private var documents: [CarDocument] {
        car.documents.sorted { $0.createdAt > $1.createdAt }
    }

    var body: some View {
        ScrollView {
            if documents.isEmpty {
                EmptyStateView(
                    symbolName: "folder.fill",
                    title: "No documents yet",
                    message: "Keep insurance, registration, warranty, and manuals here so they're always with the car."
                )
                .padding(.top, 60)
            } else {
                LazyVStack(spacing: Theme.Spacing.m) {
                    ForEach(documents) { document in
                        documentRow(document)
                    }
                }
                .padding(Theme.Spacing.l)
            }
        }
        .scrollContentBackground(.hidden)
        .background(AmbientBackground(tint: car.accentColor))
        .navigationTitle("Documents")
        .navigationBarTitleDisplayMode(.inline)
        .tint(car.accentColor)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                addMenu
            }
        }
        .photosPicker(isPresented: $isPickingPhoto, selection: $photoItem, matching: .images)
        .fileImporter(isPresented: $isImportingFile, allowedContentTypes: [.pdf, .image]) { result in
            handleFileImport(result)
        }
        .onChange(of: photoItem) { _, newValue in
            Task { await handlePhoto(newValue) }
        }
        .sheet(item: $previewItem) { item in
            QuickLookPreview(url: item.url)
                .ignoresSafeArea()
        }
        .alert("Document", isPresented: errorAlertBinding) {
            Button("OK", role: .cancel) { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
        .confirmationDialog(
            "Delete document?",
            isPresented: deleteDialogBinding,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) { deletePending() }
            Button("Cancel", role: .cancel) { documentPendingDeletion = nil }
        } message: {
            Text("This removes the document from this device.")
        }
    }

    private var errorAlertBinding: Binding<Bool> {
        Binding(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })
    }

    private var deleteDialogBinding: Binding<Bool> {
        Binding(get: { documentPendingDeletion != nil }, set: { if !$0 { documentPendingDeletion = nil } })
    }

    private var addMenu: some View {
        Menu {
            ForEach(DocumentCategory.allCases) { category in
                Menu(category.title) {
                    Button {
                        pendingCategory = category
                        isPickingPhoto = true
                    } label: {
                        Label("Choose Photo", systemImage: "photo")
                    }
                    Button {
                        pendingCategory = category
                        isImportingFile = true
                    } label: {
                        Label("Choose File", systemImage: "doc")
                    }
                }
            }
        } label: {
            Image(systemName: "plus")
        }
        .accessibilityLabel("Add document")
    }

    private func documentRow(_ document: CarDocument) -> some View {
        Button {
            HapticsManager.soft()
            openPreview(document)
        } label: {
            HStack(spacing: Theme.Spacing.m) {
                Image(systemName: document.category.symbolName)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(car.accentColor.gradient, in: RoundedRectangle(cornerRadius: 12, style: .continuous))

                VStack(alignment: .leading, spacing: 3) {
                    Text(document.title)
                        .font(.headline)
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                    Text("\(document.category.title) · \(document.createdAt.formatted(date: .abbreviated, time: .omitted))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Spacer(minLength: 0)

                Image(systemName: document.isPDF ? "doc.richtext" : "photo")
                    .foregroundStyle(.secondary)
                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.bold))
                    .foregroundStyle(.tertiary)
            }
            .padding(Theme.Spacing.l)
            .adaptiveGlass(in: RoundedRectangle(cornerRadius: Theme.Radius.control, style: .continuous))
        }
        .buttonStyle(CardPressStyle())
        .contextMenu {
            Button(role: .destructive) {
                documentPendingDeletion = document
            } label: {
                Label("Delete Document", systemImage: "trash")
            }
        }
        .accessibilityLabel("\(document.title), \(document.category.title)")
    }

    // MARK: Actions

    private func openPreview(_ document: CarDocument) {
        let safeName = document.title.replacingOccurrences(of: "/", with: "-")
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent(safeName)
            .appendingPathExtension(document.fileExtension)
        do {
            try document.fileData.write(to: url, options: .atomic)
            previewItem = PreviewDocument(url: url)
        } catch {
            errorMessage = "Couldn't open this document."
        }
    }

    private func handlePhoto(_ item: PhotosPickerItem?) async {
        guard let item, let data = try? await item.loadTransferable(type: Data.self) else { return }
        await MainActor.run {
            addDocument(data: data, fileExtension: "jpg", title: defaultTitle(for: pendingCategory))
            photoItem = nil
        }
    }

    private func handleFileImport(_ result: Result<URL, Error>) {
        switch result {
        case .success(let url):
            let didAccess = url.startAccessingSecurityScopedResource()
            defer { if didAccess { url.stopAccessingSecurityScopedResource() } }
            do {
                let data = try Data(contentsOf: url)
                let ext = url.pathExtension.isEmpty ? "dat" : url.pathExtension
                let name = url.deletingPathExtension().lastPathComponent
                addDocument(data: data, fileExtension: ext, title: name.isEmpty ? defaultTitle(for: pendingCategory) : name)
            } catch {
                errorMessage = "Couldn't read that file."
            }
        case .failure:
            errorMessage = "Couldn't import that file."
        }
    }

    private func defaultTitle(for category: DocumentCategory) -> String {
        "\(category.title) · \(Date.now.formatted(date: .abbreviated, time: .omitted))"
    }

    private func addDocument(data: Data, fileExtension: String, title: String) {
        let document = CarDocument(title: title, category: pendingCategory, fileData: data, fileExtension: fileExtension)
        document.car = car
        car.documents.append(document)
        do {
            try modelContext.save()
            HapticsManager.success()
        } catch {
            errorMessage = "Couldn't save the document."
        }
    }

    private func deletePending() {
        guard let document = documentPendingDeletion else { return }
        modelContext.delete(document)
        do {
            try modelContext.save()
            HapticsManager.warning()
        } catch {
            assertionFailure("Failed to delete document: \(error)")
        }
        documentPendingDeletion = nil
    }
}
