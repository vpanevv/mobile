import AppKit

let outputURL = URL(fileURLWithPath: "/Users/panev/panev-ios/mobile/GymCutTracker/GymCutTracker/Assets.xcassets/AppIcon.appiconset/AppIcon-1024.png")
let size = CGSize(width: 1024, height: 1024)

let image = NSImage(size: size)
image.lockFocus()

guard let context = NSGraphicsContext.current?.cgContext else {
    fatalError("Missing graphics context")
}

let background = CGGradient(
    colorsSpace: CGColorSpaceCreateDeviceRGB(),
    colors: [
        NSColor(calibratedRed: 0.015, green: 0.018, blue: 0.020, alpha: 1).cgColor,
        NSColor(calibratedRed: 0.050, green: 0.060, blue: 0.065, alpha: 1).cgColor,
        NSColor(calibratedRed: 0.012, green: 0.020, blue: 0.018, alpha: 1).cgColor
    ] as CFArray,
    locations: [0, 0.55, 1]
)!
context.drawLinearGradient(background, start: CGPoint(x: 0, y: 1024), end: CGPoint(x: 1024, y: 0), options: [])

let accent = NSColor(calibratedRed: 0.31, green: 1.0, blue: 0.42, alpha: 1)
let blueAccent = NSColor(calibratedRed: 0.15, green: 0.58, blue: 1.0, alpha: 1)

context.setFillColor(accent.withAlphaComponent(0.16).cgColor)
context.fillEllipse(in: CGRect(x: 152, y: 120, width: 720, height: 720))

context.setFillColor(blueAccent.withAlphaComponent(0.10).cgColor)
context.fillEllipse(in: CGRect(x: 570, y: 580, width: 260, height: 260))

let glass = NSBezierPath(roundedRect: CGRect(x: 132, y: 132, width: 760, height: 760), xRadius: 170, yRadius: 170)
context.setStrokeColor(NSColor.white.withAlphaComponent(0.10).cgColor)
context.setLineWidth(4)
context.addPath(glass.cgPath)
context.strokePath()

func roundedRect(_ rect: CGRect, radius: CGFloat) {
    context.addPath(NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius).cgPath)
}

context.saveGState()
context.translateBy(x: 512, y: 512)
context.rotate(by: -0.18)
context.translateBy(x: -512, y: -512)

let shadow = NSShadow()
shadow.shadowColor = accent.withAlphaComponent(0.38)
shadow.shadowBlurRadius = 44
shadow.shadowOffset = CGSize(width: 0, height: -8)
shadow.set()

let dumbbellGradient = CGGradient(
    colorsSpace: CGColorSpaceCreateDeviceRGB(),
    colors: [
        NSColor(calibratedRed: 0.70, green: 1.0, blue: 0.74, alpha: 1).cgColor,
        accent.cgColor,
        NSColor(calibratedRed: 0.16, green: 0.78, blue: 0.28, alpha: 1).cgColor
    ] as CFArray,
    locations: [0, 0.52, 1]
)!

let dumbbellPath = CGMutablePath()
dumbbellPath.addRoundedRect(in: CGRect(x: 286, y: 472, width: 452, height: 80), cornerWidth: 40, cornerHeight: 40)
dumbbellPath.addRoundedRect(in: CGRect(x: 156, y: 392, width: 86, height: 240), cornerWidth: 34, cornerHeight: 34)
dumbbellPath.addRoundedRect(in: CGRect(x: 246, y: 346, width: 96, height: 332), cornerWidth: 38, cornerHeight: 38)
dumbbellPath.addRoundedRect(in: CGRect(x: 682, y: 346, width: 96, height: 332), cornerWidth: 38, cornerHeight: 38)
dumbbellPath.addRoundedRect(in: CGRect(x: 782, y: 392, width: 86, height: 240), cornerWidth: 34, cornerHeight: 34)

context.saveGState()
context.addPath(dumbbellPath)
context.clip()
context.drawLinearGradient(dumbbellGradient, start: CGPoint(x: 190, y: 690), end: CGPoint(x: 850, y: 330), options: [])
context.restoreGState()

context.setStrokeColor(NSColor.white.withAlphaComponent(0.26).cgColor)
context.setLineWidth(8)
context.addPath(dumbbellPath)
context.strokePath()

context.setFillColor(NSColor.white.withAlphaComponent(0.20).cgColor)
context.fillEllipse(in: CGRect(x: 382, y: 536, width: 96, height: 22))

context.restoreGState()

image.unlockFocus()

guard
    let tiff = image.tiffRepresentation,
    let bitmap = NSBitmapImageRep(data: tiff),
    let png = bitmap.representation(using: .png, properties: [:])
else {
    fatalError("Unable to encode icon")
}

try png.write(to: outputURL)
