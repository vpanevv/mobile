import UIKit
import ImageIO
import Vision

/// On-disk storage for images filed into user albums.
nonisolated enum ImageStore {
    nonisolated(unsafe) private static let cache = NSCache<NSString, UIImage>()

    static var directory: URL {
        let url = URL.applicationSupportDirectory.appending(path: "Shots", directoryHint: .isDirectory)
        try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    static func url(for fileName: String) -> URL {
        directory.appending(path: fileName)
    }

    static func save(_ data: Data) throws -> String {
        let name = UUID().uuidString + ".img"
        try data.write(to: url(for: name), options: .atomic)
        return name
    }

    static func delete(_ fileName: String) {
        try? FileManager.default.removeItem(at: url(for: fileName))
        cache.removeAllObjects()
    }

    static func data(for fileName: String) -> Data? {
        try? Data(contentsOf: url(for: fileName))
    }

    /// Downsampled image, decoded off the main thread.
    static func thumbnail(for fileName: String, maxPixel: CGFloat) async -> UIImage? {
        let key = "\(fileName)#\(Int(maxPixel))" as NSString
        if let cached = cache.object(forKey: key) { return cached }
        let fileURL = url(for: fileName)
        let image = await Task.detached(priority: .userInitiated) { () -> UIImage? in
            guard let source = CGImageSourceCreateWithURL(fileURL as CFURL, nil) else { return nil }
            let options: [CFString: Any] = [
                kCGImageSourceCreateThumbnailFromImageAlways: true,
                kCGImageSourceCreateThumbnailWithTransform: true,
                kCGImageSourceShouldCacheImmediately: true,
                kCGImageSourceThumbnailMaxPixelSize: maxPixel,
            ]
            guard let cg = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary) else { return nil }
            return UIImage(cgImage: cg)
        }.value
        if let image { cache.setObject(image, forKey: key) }
        return image
    }

    static var bytesUsed: Int64 {
        let files = (try? FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: [.fileSizeKey])) ?? []
        return files.reduce(0) { total, file in
            total + Int64((try? file.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0)
        }
    }
}

/// On-device OCR so screenshots are searchable by the text inside them.
nonisolated enum TextRecognizer {
    static func text(in data: Data) async -> String {
        var request = RecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true
        guard let observations = try? await request.perform(on: data) else { return "" }
        return observations
            .compactMap { $0.topCandidates(1).first?.string }
            .joined(separator: "\n")
    }
}
