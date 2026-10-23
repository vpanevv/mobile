import SwiftUI
import SwiftData
import PhotosUI

/// Filing, moving and removing screenshots.
enum ShotActions {
    /// Files a screenshot into `album`. A library screenshot is copied in; a
    /// screenshot already in another album is moved.
    static func file(_ ref: ShotRef, into album: Album, context: ModelContext, library: PhotoLibraryService) async {
        switch ref {
        case .saved(let shot):
            shot.album = album
            shot.addedAt = .now
        case .asset(let asset):
            guard !exists(assetID: asset.localIdentifier, in: album, context: context),
                  let data = await library.imageData(for: asset) else { return }
            insert(data: data, into: album, assetID: asset.localIdentifier, createdAt: asset.creationDate ?? .now, context: context)
        }
        try? context.save()
    }

    static func importItems(_ items: [PhotosPickerItem], into album: Album, context: ModelContext) async {
        for item in items {
            if let id = item.itemIdentifier, exists(assetID: id, in: album, context: context) { continue }
            guard let data = try? await item.loadTransferable(type: Data.self) else { continue }
            insert(data: data, into: album, assetID: item.itemIdentifier, createdAt: .now, context: context)
        }
        try? context.save()
    }

    static func remove(_ shot: SavedShot, context: ModelContext) {
        ImageStore.delete(shot.fileName)
        context.delete(shot)
        try? context.save()
    }

    private static func insert(data: Data, into album: Album, assetID: String?, createdAt: Date, context: ModelContext) {
        guard let fileName = try? ImageStore.save(data) else { return }
        let shot = SavedShot(album: album, fileName: fileName, sourceAssetID: assetID, createdAt: createdAt)
        context.insert(shot)
        Task {
            let text = await TextRecognizer.text(in: data)
            if !shot.isDeleted { shot.recognizedText = text }
        }
    }

    private static func exists(assetID: String, in album: Album, context: ModelContext) -> Bool {
        let raw = album.rawValue
        let descriptor = FetchDescriptor<SavedShot>(predicate: #Predicate { $0.sourceAssetID == assetID && $0.albumRaw == raw })
        return ((try? context.fetchCount(descriptor)) ?? 0) > 0
    }
}
