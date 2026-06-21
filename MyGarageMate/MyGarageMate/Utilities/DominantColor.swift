import CoreImage
import UIKit

/// Extracts a representative accent color from a car photo, fully on-device.
enum DominantColor {
    private static let context = CIContext(options: [.workingColorSpace: NSNull()])

    /// Returns a hex string (e.g. "#3A7BD5") for the photo's average color,
    /// nudged into a range that reads well as a UI accent.
    static func hex(from data: Data) -> String? {
        guard let image = UIImage(data: data), let cgImage = image.cgImage else { return nil }

        let ciImage = CIImage(cgImage: cgImage)
        guard let filter = CIFilter(name: "CIAreaAverage", parameters: [
            kCIInputImageKey: ciImage,
            kCIInputExtentKey: CIVector(cgRect: ciImage.extent)
        ]), let output = filter.outputImage else {
            return nil
        }

        var bitmap = [UInt8](repeating: 0, count: 4)
        context.render(
            output,
            toBitmap: &bitmap,
            rowBytes: 4,
            bounds: CGRect(x: 0, y: 0, width: 1, height: 1),
            format: .RGBA8,
            colorSpace: nil
        )

        let base = UIColor(
            red: CGFloat(bitmap[0]) / 255,
            green: CGFloat(bitmap[1]) / 255,
            blue: CGFloat(bitmap[2]) / 255,
            alpha: 1
        )

        var h: CGFloat = 0, s: CGFloat = 0, v: CGFloat = 0, a: CGFloat = 0
        base.getHue(&h, saturation: &s, brightness: &v, alpha: &a)

        // Keep it lively but legible as a tint, without inventing color on greys.
        s = min(1, max(0.25, s * 1.25))
        v = min(0.85, max(0.45, v))

        let adjusted = UIColor(hue: h, saturation: s, brightness: v, alpha: 1)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, aa: CGFloat = 0
        adjusted.getRed(&r, green: &g, blue: &b, alpha: &aa)

        return String(format: "#%02X%02X%02X", Int(r * 255), Int(g * 255), Int(b * 255))
    }
}
