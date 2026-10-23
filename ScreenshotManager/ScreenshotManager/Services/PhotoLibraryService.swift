import Photos
import UIKit
import Observation

/// Live view of the screenshots in the user's Photos library.
///
/// iOS saves every screenshot to Photos, so the "Recent" album simply mirrors
/// the library's screenshots and updates the moment a new one lands, via
/// `PHPhotoLibraryChangeObserver`.
@Observable
final class PhotoLibraryService: NSObject, PHPhotoLibraryChangeObserver {
    private(set) var status: PHAuthorizationStatus
    private(set) var screenshots: [PHAsset] = []
    /// Bumped when the user takes a screenshot while the app is open.
    private(set) var captureCount = 0

    @ObservationIgnored private var fetchResult: PHFetchResult<PHAsset>?
    @ObservationIgnored private var isObserving = false
    @ObservationIgnored private let imageManager = PHCachingImageManager()

    override init() {
        status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        super.init()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(didTakeScreenshot),
            name: UIApplication.userDidTakeScreenshotNotification,
            object: nil
        )
    }

    var isAuthorized: Bool { status == .authorized || status == .limited }

    func bootstrap() async {
        if status == .notDetermined {
            status = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
        }
        if isAuthorized { start() }
    }

    func refreshStatus() {
        status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        if isAuthorized { start() }
    }

    private func start() {
        if !isObserving {
            PHPhotoLibrary.shared().register(self)
            isObserving = true
        }
        reload()
    }

    private func reload() {
        let options = PHFetchOptions()
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        options.predicate = NSPredicate(
            format: "(mediaSubtypes & %d) != 0",
            PHAssetMediaSubtype.photoScreenshot.rawValue
        )
        let result = PHAsset.fetchAssets(with: .image, options: options)
        fetchResult = result
        screenshots = result.objects(at: IndexSet(integersIn: 0..<result.count))
    }

    nonisolated func photoLibraryDidChange(_ changeInstance: PHChange) {
        Task { @MainActor in self.reload() }
    }

    @objc private func didTakeScreenshot() {
        captureCount += 1
    }

    // MARK: - Images

    /// Tries the on-device copy first, then a fast local derivative, and only
    /// then iCloud, so thumbnails show up even when originals are offloaded.
    func image(for asset: PHAsset, targetSize: CGSize, contentMode: PHImageContentMode = .aspectFill) async -> UIImage? {
        let attempts: [(PHImageRequestOptionsDeliveryMode, Bool)] = [
            (.highQualityFormat, false),
            (.fastFormat, false),
            (.highQualityFormat, true),
        ]
        for (mode, network) in attempts {
            if let image = await requestImage(asset, targetSize: targetSize, contentMode: contentMode, mode: mode, network: network) {
                return image
            }
        }
        return nil
    }

    private func requestImage(_ asset: PHAsset, targetSize: CGSize, contentMode: PHImageContentMode,
                              mode: PHImageRequestOptionsDeliveryMode, network: Bool) async -> UIImage? {
        let options = PHImageRequestOptions()
        options.deliveryMode = mode
        options.resizeMode = .fast
        options.isNetworkAccessAllowed = network
        return await withCheckedContinuation { continuation in
            imageManager.requestImage(for: asset, targetSize: targetSize, contentMode: contentMode, options: options) { image, info in
                if image == nil { print("DBG nil image", asset.localIdentifier, mode.rawValue, network, info ?? [:]) }
                continuation.resume(returning: image)
            }
        }
    }

    func imageData(for asset: PHAsset) async -> Data? {
        for network in [false, true] {
            let options = PHImageRequestOptions()
            options.isNetworkAccessAllowed = network
            options.version = .current
            let data: Data? = await withCheckedContinuation { continuation in
                imageManager.requestImageDataAndOrientation(for: asset, options: options) { data, _, _, _ in
                    continuation.resume(returning: data)
                }
            }
            if let data { return data }
        }
        // Original unavailable (e.g. offloaded to iCloud and offline): keep a
        // large rendered copy instead.
        let image = await image(for: asset, targetSize: CGSize(width: 2000, height: 2000), contentMode: .aspectFit)
        return image?.pngData()
    }

    func deleteFromLibrary(_ asset: PHAsset) async throws {
        try await PHPhotoLibrary.shared().performChanges {
            PHAssetChangeRequest.deleteAssets([asset] as NSArray)
        }
    }
}
