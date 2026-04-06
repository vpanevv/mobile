import AppKit

let sourceURL = URL(fileURLWithPath: "/Users/panev/panev-ios/mobile/TimeMap/WaterTracker/Assets.xcassets/AppIcon.appiconset/AppIcon-1024.png")
let outputDirectory = sourceURL.deletingLastPathComponent()

let iconSpecs: [(String, CGFloat)] = [
    ("AppIcon-1024.png", 1024),
    ("Icon-20@2x.png", 40),
    ("Icon-20@3x.png", 60),
    ("Icon-29@2x.png", 58),
    ("Icon-29@3x.png", 87),
    ("Icon-40@2x.png", 80),
    ("Icon-40@3x.png", 120),
    ("Icon-60@2x.png", 120),
    ("Icon-60@3x.png", 180),
    ("Icon-20-ipad@1x.png", 20),
    ("Icon-20-ipad@2x.png", 40),
    ("Icon-29-ipad@1x.png", 29),
    ("Icon-29-ipad@2x.png", 58),
    ("Icon-40-ipad@1x.png", 40),
    ("Icon-40-ipad@2x.png", 80),
    ("Icon-76@1x.png", 76),
    ("Icon-76@2x.png", 152),
    ("Icon-83.5@2x.png", 167)
]

guard let sourceImage = NSImage(contentsOf: sourceURL) else {
    fatalError("Missing source icon")
}

for (fileName, side) in iconSpecs {
    let pixelSize = Int(side)

    guard let bitmap = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: pixelSize,
        pixelsHigh: pixelSize,
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: 0,
        bitsPerPixel: 0
    ) else {
        fatalError("Unable to create bitmap for \(fileName)")
    }

    bitmap.size = NSSize(width: side, height: side)

    NSGraphicsContext.saveGraphicsState()
    guard let context = NSGraphicsContext(bitmapImageRep: bitmap) else {
        fatalError("Unable to create graphics context for \(fileName)")
    }
    NSGraphicsContext.current = context
    sourceImage.draw(in: NSRect(x: 0, y: 0, width: side, height: side), from: .zero, operation: .copy, fraction: 1)
    context.flushGraphics()
    NSGraphicsContext.restoreGraphicsState()

    guard let pngData = bitmap.representation(using: .png, properties: [:]) else {
        fatalError("Unable to encode \(fileName)")
    }

    try pngData.write(to: outputDirectory.appendingPathComponent(fileName))
}
