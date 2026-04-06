import AppKit

let outputURL = URL(fileURLWithPath: "/Users/panev/panev-ios/mobile/WaterTracker/WaterTracker/Assets.xcassets/AppIcon.appiconset/AppIcon-1024.png")
let size = CGSize(width: 1024, height: 1024)

let image = NSImage(size: size)
image.lockFocus()

guard let context = NSGraphicsContext.current?.cgContext else {
    fatalError("Missing graphics context")
}

let colors = [
    NSColor(calibratedRed: 0.05, green: 0.16, blue: 0.31, alpha: 1).cgColor,
    NSColor(calibratedRed: 0.11, green: 0.51, blue: 0.85, alpha: 1).cgColor,
    NSColor(calibratedRed: 0.21, green: 0.87, blue: 0.92, alpha: 1).cgColor
]

let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors as CFArray, locations: [0, 0.55, 1])!
context.drawLinearGradient(gradient, start: CGPoint(x: 0, y: 1024), end: CGPoint(x: 1024, y: 0), options: [])

context.setFillColor(NSColor.white.withAlphaComponent(0.12).cgColor)
context.fillEllipse(in: CGRect(x: 120, y: 580, width: 320, height: 320))
context.fillEllipse(in: CGRect(x: 640, y: 120, width: 220, height: 220))

let droplet = NSBezierPath()
droplet.move(to: CGPoint(x: 512, y: 790))
droplet.curve(to: CGPoint(x: 720, y: 448), controlPoint1: CGPoint(x: 650, y: 676), controlPoint2: CGPoint(x: 742, y: 564))
droplet.curve(to: CGPoint(x: 512, y: 232), controlPoint1: CGPoint(x: 720, y: 328), controlPoint2: CGPoint(x: 624, y: 232))
droplet.curve(to: CGPoint(x: 304, y: 448), controlPoint1: CGPoint(x: 400, y: 232), controlPoint2: CGPoint(x: 304, y: 328))
droplet.curve(to: CGPoint(x: 512, y: 790), controlPoint1: CGPoint(x: 282, y: 564), controlPoint2: CGPoint(x: 374, y: 676))
droplet.close()

context.saveGState()
context.addPath(droplet.cgPath)
context.clip()

let dropletGradient = CGGradient(
    colorsSpace: CGColorSpaceCreateDeviceRGB(),
    colors: [
        NSColor.white.withAlphaComponent(0.96).cgColor,
        NSColor(calibratedRed: 0.63, green: 0.94, blue: 1.0, alpha: 1).cgColor,
        NSColor(calibratedRed: 0.15, green: 0.58, blue: 0.96, alpha: 1).cgColor
    ] as CFArray,
    locations: [0, 0.35, 1]
)!
context.drawLinearGradient(dropletGradient, start: CGPoint(x: 350, y: 760), end: CGPoint(x: 680, y: 230), options: [])

context.setFillColor(NSColor.white.withAlphaComponent(0.18).cgColor)
context.fillEllipse(in: CGRect(x: 408, y: 560, width: 150, height: 170))
context.restoreGState()

context.setStrokeColor(NSColor.white.withAlphaComponent(0.32).cgColor)
context.setLineWidth(10)
context.addPath(droplet.cgPath)
context.strokePath()

let glass = NSBezierPath(roundedRect: CGRect(x: 360, y: 214, width: 304, height: 84), xRadius: 28, yRadius: 28)
context.saveGState()
context.addPath(glass.cgPath)
context.clip()
let glassGradient = CGGradient(
    colorsSpace: CGColorSpaceCreateDeviceRGB(),
    colors: [
        NSColor.white.withAlphaComponent(0.92).cgColor,
        NSColor.white.withAlphaComponent(0.56).cgColor
    ] as CFArray,
    locations: [0, 1]
)!
context.drawLinearGradient(glassGradient, start: CGPoint(x: 360, y: 298), end: CGPoint(x: 664, y: 214), options: [])
context.restoreGState()

context.setStrokeColor(NSColor.white.withAlphaComponent(0.20).cgColor)
context.setLineWidth(6)
context.addPath(glass.cgPath)
context.strokePath()

image.unlockFocus()

guard
    let tiff = image.tiffRepresentation,
    let bitmap = NSBitmapImageRep(data: tiff),
    let png = bitmap.representation(using: .png, properties: [:])
else {
    fatalError("Unable to encode icon")
}

try png.write(to: outputURL)
