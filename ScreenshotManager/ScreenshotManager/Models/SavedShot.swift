import Foundation
import SwiftData
import Photos

/// An image the user filed into one of the user albums. The image bytes live
/// on disk (see `ImageStore`); `sourceAssetID` links back to the Photos asset
/// it came from, when there is one.
@Model
final class SavedShot {
    @Attribute(.unique) var id: UUID
    var albumRaw: String
    var fileName: String
    var sourceAssetID: String?
    var createdAt: Date
    var addedAt: Date
    var recognizedText: String
    var isFavorite: Bool

    init(album: Album, fileName: String, sourceAssetID: String?, createdAt: Date) {
        self.id = UUID()
        self.albumRaw = album.rawValue
        self.fileName = fileName
        self.sourceAssetID = sourceAssetID
        self.createdAt = createdAt
        self.addedAt = .now
        self.recognizedText = ""
        self.isFavorite = false
    }

    var album: Album {
        get { Album(rawValue: albumRaw) ?? .personal }
        set { albumRaw = newValue.rawValue }
    }
}

/// A single screenshot regardless of where it lives.
enum ShotRef: Identifiable, Hashable {
    case asset(PHAsset)
    case saved(SavedShot)

    var id: String {
        switch self {
        case .asset(let asset): "a:" + asset.localIdentifier
        case .saved(let shot): "s:" + shot.id.uuidString
        }
    }

    var thumb: ThumbSource {
        switch self {
        case .asset(let asset): .asset(asset)
        case .saved(let shot): .file(shot.fileName)
        }
    }

    var date: Date? {
        switch self {
        case .asset(let asset): asset.creationDate
        case .saved(let shot): shot.createdAt
        }
    }
}

enum ThumbSource: Hashable {
    case asset(PHAsset)
    case file(String)

    var key: String {
        switch self {
        case .asset(let asset): asset.localIdentifier
        case .file(let name): name
        }
    }
}
