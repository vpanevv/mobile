import AppKit

enum IconVariant: String, CaseIterable {
    case standard
    case dark
    case tinted

    var fileName: String {
        switch self {
        case .standard:
            return "AppIcon-1024.png"
        case .dark:
            return "AppIcon-1024-dark.png"
        case .tinted:
            return "AppIcon-1024-tinted.png"
        }
    }
}

let outputDirectory = URL(fileURLWithPath: "/Users/panev/panev-ios/mobile/TimeMap/TimeMap/Assets.xcassets/AppIcon.appiconset", isDirectory: true)
let size = CGSize(width: 1024, height: 1024)

for variant in IconVariant.allCases {
    let image = NSImage(size: size)
    image.lockFocus()

    guard let context = NSGraphicsContext.current?.cgContext else {
        fatalError("Unable to create graphics context")
    }

    drawBackground(in: context, size: size, variant: variant)
    drawGrid(in: context, size: size, variant: variant)
    drawOrbitGlow(in: context, size: size, variant: variant)
    drawGlobe(in: context, size: size, variant: variant)
    drawClockDetails(in: context, size: size, variant: variant)
    drawGloss(in: context, size: size, variant: variant)

    image.unlockFocus()

    guard
        let tiff = image.tiffRepresentation,
        let rep = NSBitmapImageRep(data: tiff),
        let png = rep.representation(using: .png, properties: [:])
    else {
        fatalError("Unable to encode image")
    }

    try png.write(to: outputDirectory.appendingPathComponent(variant.fileName))
}

func drawBackground(in context: CGContext, size: CGSize, variant: IconVariant) {
    let colors: [CGColor]

    switch variant {
    case .standard:
        colors = [
            NSColor(calibratedRed: 0.08, green: 0.19, blue: 0.53, alpha: 1).cgColor,
            NSColor(calibratedRed: 0.14, green: 0.28, blue: 0.72, alpha: 1).cgColor,
            NSColor(calibratedRed: 0.10, green: 0.58, blue: 0.93, alpha: 1).cgColor
        ]
    case .dark:
        colors = [
            NSColor(calibratedRed: 0.04, green: 0.10, blue: 0.30, alpha: 1).cgColor,
            NSColor(calibratedRed: 0.08, green: 0.20, blue: 0.54, alpha: 1).cgColor,
            NSColor(calibratedRed: 0.09, green: 0.42, blue: 0.80, alpha: 1).cgColor
        ]
    case .tinted:
        colors = [
            NSColor(calibratedWhite: 0.10, alpha: 1).cgColor,
            NSColor(calibratedWhite: 0.18, alpha: 1).cgColor,
            NSColor(calibratedWhite: 0.28, alpha: 1).cgColor
        ]
    }

    let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors as CFArray, locations: [0.0, 0.55, 1.0])!
    context.drawLinearGradient(gradient, start: CGPoint(x: 0, y: size.height), end: CGPoint(x: size.width, y: 0), options: [])

    context.setFillColor((variant == .tinted ? NSColor.white.withAlphaComponent(0.08) : NSColor(calibratedRed: 0.57, green: 0.87, blue: 1.0, alpha: 0.22)).cgColor)
    context.addEllipse(in: CGRect(x: 560, y: 620, width: 340, height: 340))
    context.fillPath()

    context.setFillColor((variant == .tinted ? NSColor.white.withAlphaComponent(0.05) : NSColor(calibratedRed: 0.35, green: 0.46, blue: 0.95, alpha: 0.18)).cgColor)
    context.addEllipse(in: CGRect(x: 100, y: 120, width: 420, height: 420))
    context.fillPath()
}

func drawGrid(in context: CGContext, size: CGSize, variant: IconVariant) {
    let alpha: CGFloat = variant == .tinted ? 0.12 : 0.10
    context.setStrokeColor(NSColor.white.withAlphaComponent(alpha).cgColor)
    context.setLineWidth(2)

    stride(from: 88.0, through: 936.0, by: 96.0).forEach { value in
        context.move(to: CGPoint(x: value, y: 70))
        context.addLine(to: CGPoint(x: value, y: 954))
        context.strokePath()

        context.move(to: CGPoint(x: 70, y: value))
        context.addLine(to: CGPoint(x: 954, y: value))
        context.strokePath()
    }
}

func drawOrbitGlow(in context: CGContext, size: CGSize, variant: IconVariant) {
    context.saveGState()
    context.translateBy(x: size.width / 2, y: size.height / 2 + 18)

    let orbitRect = CGRect(x: -278, y: -160, width: 556, height: 320)
    context.setStrokeColor((variant == .tinted ? NSColor.white.withAlphaComponent(0.24) : NSColor(calibratedRed: 0.61, green: 0.92, blue: 1.0, alpha: 0.34)).cgColor)
    context.setLineWidth(20)
    context.strokeEllipse(in: orbitRect)

    context.setStrokeColor(NSColor.white.withAlphaComponent(variant == .tinted ? 0.18 : 0.12).cgColor)
    context.setLineWidth(6)
    context.strokeEllipse(in: orbitRect.insetBy(dx: 10, dy: 10))
    context.restoreGState()
}

func drawGlobe(in context: CGContext, size: CGSize, variant: IconVariant) {
    let globeRect = CGRect(x: 228, y: 216, width: 568, height: 568)
    let oceanColors: [CGColor]

    switch variant {
    case .standard:
        oceanColors = [
            NSColor(calibratedRed: 0.30, green: 0.86, blue: 0.98, alpha: 1).cgColor,
            NSColor(calibratedRed: 0.10, green: 0.48, blue: 0.90, alpha: 1).cgColor,
            NSColor(calibratedRed: 0.03, green: 0.13, blue: 0.34, alpha: 1).cgColor
        ]
    case .dark:
        oceanColors = [
            NSColor(calibratedRed: 0.21, green: 0.66, blue: 0.90, alpha: 1).cgColor,
            NSColor(calibratedRed: 0.08, green: 0.33, blue: 0.70, alpha: 1).cgColor,
            NSColor(calibratedRed: 0.02, green: 0.08, blue: 0.22, alpha: 1).cgColor
        ]
    case .tinted:
        oceanColors = [
            NSColor.white.withAlphaComponent(0.92).cgColor,
            NSColor.white.withAlphaComponent(0.74).cgColor,
            NSColor.white.withAlphaComponent(0.46).cgColor
        ]
    }

    let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: oceanColors as CFArray, locations: [0.0, 0.42, 1.0])!
    context.saveGState()
    context.addEllipse(in: globeRect)
    context.clip()
    context.drawRadialGradient(
        gradient,
        startCenter: CGPoint(x: globeRect.minX + globeRect.width * 0.34, y: globeRect.minY + globeRect.height * 0.72),
        startRadius: 12,
        endCenter: CGPoint(x: globeRect.midX, y: globeRect.midY),
        endRadius: globeRect.width * 0.56,
        options: []
    )

    drawLandmasses(in: context, variant: variant)
    drawLatitudeLongitude(in: context, globeRect: globeRect, variant: variant)

    context.setFillColor(NSColor.white.withAlphaComponent(variant == .tinted ? 0.12 : 0.10).cgColor)
    context.addEllipse(in: CGRect(x: 280, y: 510, width: 160, height: 76))
    context.fillPath()

    context.setFillColor(NSColor.white.withAlphaComponent(variant == .tinted ? 0.08 : 0.07).cgColor)
    context.addEllipse(in: CGRect(x: 544, y: 614, width: 146, height: 60))
    context.fillPath()

    context.restoreGState()

    context.setStrokeColor(NSColor.white.withAlphaComponent(variant == .tinted ? 0.56 : 0.28).cgColor)
    context.setLineWidth(4)
    context.strokeEllipse(in: globeRect)

    context.setStrokeColor((variant == .tinted ? NSColor.white.withAlphaComponent(0.20) : NSColor(calibratedRed: 0.63, green: 0.92, blue: 1.0, alpha: 0.20)).cgColor)
    context.setLineWidth(22)
    context.strokeEllipse(in: globeRect.insetBy(dx: -12, dy: -12))
}

func drawLandmasses(in context: CGContext, variant: IconVariant) {
    let landPalette: [(CGColor, CGColor)] = {
        switch variant {
        case .standard:
            return [
                (NSColor(calibratedRed: 0.76, green: 0.84, blue: 0.48, alpha: 1).cgColor, NSColor(calibratedRed: 0.26, green: 0.43, blue: 0.19, alpha: 1).cgColor),
                (NSColor(calibratedRed: 0.88, green: 0.73, blue: 0.46, alpha: 1).cgColor, NSColor(calibratedRed: 0.48, green: 0.34, blue: 0.16, alpha: 1).cgColor)
            ]
        case .dark:
            return [
                (NSColor(calibratedRed: 0.66, green: 0.74, blue: 0.42, alpha: 1).cgColor, NSColor(calibratedRed: 0.22, green: 0.34, blue: 0.16, alpha: 1).cgColor),
                (NSColor(calibratedRed: 0.75, green: 0.63, blue: 0.40, alpha: 1).cgColor, NSColor(calibratedRed: 0.40, green: 0.28, blue: 0.14, alpha: 1).cgColor)
            ]
        case .tinted:
            return [
                (NSColor.white.withAlphaComponent(0.96).cgColor, NSColor.white.withAlphaComponent(0.56).cgColor),
                (NSColor.white.withAlphaComponent(0.88).cgColor, NSColor.white.withAlphaComponent(0.44).cgColor)
            ]
        }
    }()

    let shapes: [(NSBezierPath, Int)] = [
        (path([
            CGPoint(x: 325, y: 607), CGPoint(x: 362, y: 682), CGPoint(x: 432, y: 713), CGPoint(x: 468, y: 672),
            CGPoint(x: 468, y: 618), CGPoint(x: 438, y: 571), CGPoint(x: 416, y: 524), CGPoint(x: 376, y: 502),
            CGPoint(x: 338, y: 534)
        ]), 0),
        (path([
            CGPoint(x: 432, y: 480), CGPoint(x: 466, y: 458), CGPoint(x: 490, y: 408), CGPoint(x: 480, y: 332),
            CGPoint(x: 450, y: 265), CGPoint(x: 408, y: 236), CGPoint(x: 390, y: 292), CGPoint(x: 400, y: 368)
        ]), 0),
        (path([
            CGPoint(x: 508, y: 620), CGPoint(x: 538, y: 674), CGPoint(x: 592, y: 688), CGPoint(x: 626, y: 654),
            CGPoint(x: 610, y: 620), CGPoint(x: 566, y: 604), CGPoint(x: 536, y: 594)
        ]), 0),
        (path([
            CGPoint(x: 566, y: 578), CGPoint(x: 622, y: 610), CGPoint(x: 700, y: 602), CGPoint(x: 738, y: 560),
            CGPoint(x: 742, y: 500), CGPoint(x: 704, y: 466), CGPoint(x: 646, y: 462), CGPoint(x: 610, y: 430),
            CGPoint(x: 578, y: 446), CGPoint(x: 560, y: 500)
        ]), 1),
        (path([
            CGPoint(x: 610, y: 432), CGPoint(x: 652, y: 414), CGPoint(x: 694, y: 390), CGPoint(x: 730, y: 356),
            CGPoint(x: 712, y: 320), CGPoint(x: 664, y: 304), CGPoint(x: 616, y: 318), CGPoint(x: 590, y: 354)
        ]), 1),
        (path([
            CGPoint(x: 688, y: 320), CGPoint(x: 732, y: 310), CGPoint(x: 746, y: 278), CGPoint(x: 718, y: 248),
            CGPoint(x: 674, y: 256), CGPoint(x: 662, y: 286)
        ]), 1),
        (path([
            CGPoint(x: 560, y: 646), CGPoint(x: 578, y: 694), CGPoint(x: 618, y: 718), CGPoint(x: 660, y: 690),
            CGPoint(x: 640, y: 642), CGPoint(x: 600, y: 626)
        ]), 0)
    ]

    for (shape, paletteIndex) in shapes {
        let (top, bottom) = landPalette[paletteIndex]
        context.saveGState()
        context.addPath(shape.cgPath)
        context.clip()

        let bounds = shape.bounds
        let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: [top, bottom] as CFArray, locations: [0, 1])!
        context.drawLinearGradient(gradient, start: CGPoint(x: bounds.minX, y: bounds.maxY), end: CGPoint(x: bounds.maxX, y: bounds.minY), options: [])
        context.restoreGState()

        context.setStrokeColor(NSColor.white.withAlphaComponent(variant == .tinted ? 0.36 : 0.14).cgColor)
        context.setLineWidth(3)
        context.addPath(shape.cgPath)
        context.strokePath()
    }
}

func drawLatitudeLongitude(in context: CGContext, globeRect: CGRect, variant: IconVariant) {
    context.setStrokeColor(NSColor.white.withAlphaComponent(variant == .tinted ? 0.18 : 0.08).cgColor)
    context.setLineWidth(2)

    [0.78, 0.56].forEach { scale in
        context.saveGState()
        context.translateBy(x: globeRect.midX, y: globeRect.midY)
        context.scaleBy(x: 1, y: scale)
        context.addEllipse(in: CGRect(x: -globeRect.width / 2, y: -globeRect.height / 2, width: globeRect.width, height: globeRect.height))
        context.strokePath()
        context.restoreGState()
    }

    [0.78, 0.54].forEach { scale in
        context.saveGState()
        context.translateBy(x: globeRect.midX, y: globeRect.midY)
        context.scaleBy(x: scale, y: 1)
        context.addEllipse(in: CGRect(x: -globeRect.width / 2, y: -globeRect.height / 2, width: globeRect.width, height: globeRect.height))
        context.strokePath()
        context.restoreGState()
    }
}

func drawClockDetails(in context: CGContext, size: CGSize, variant: IconVariant) {
    let center = CGPoint(x: size.width / 2, y: size.height / 2)

    context.setStrokeColor((variant == .tinted ? NSColor.white.withAlphaComponent(0.52) : NSColor.white.withAlphaComponent(0.22)).cgColor)
    context.setLineWidth(24)
    context.addEllipse(in: CGRect(x: center.x - 214, y: center.y - 214, width: 428, height: 428))
    context.strokePath()

    context.setStrokeColor((variant == .tinted ? NSColor.white.withAlphaComponent(0.78) : NSColor(calibratedRed: 0.96, green: 0.99, blue: 1.0, alpha: 0.92)).cgColor)
    context.setLineCap(.round)
    context.setLineWidth(34)
    context.move(to: center)
    context.addLine(to: CGPoint(x: center.x, y: center.y + 118))
    context.strokePath()

    context.setLineWidth(26)
    context.move(to: center)
    context.addLine(to: CGPoint(x: center.x + 96, y: center.y - 42))
    context.strokePath()

    context.setFillColor((variant == .tinted ? NSColor.white : NSColor(calibratedRed: 1.0, green: 0.77, blue: 0.42, alpha: 1)).cgColor)
    context.addEllipse(in: CGRect(x: center.x - 24, y: center.y - 24, width: 48, height: 48))
    context.fillPath()
}

func drawGloss(in context: CGContext, size: CGSize, variant: IconVariant) {
    let glossRect = CGRect(x: 184, y: 598, width: 424, height: 190)
    let gradient = CGGradient(
        colorsSpace: CGColorSpaceCreateDeviceRGB(),
        colors: [
            NSColor.white.withAlphaComponent(variant == .tinted ? 0.24 : 0.20).cgColor,
            NSColor.white.withAlphaComponent(0).cgColor
        ] as CFArray,
        locations: [0, 1]
    )!

    context.saveGState()
    let glossPath = NSBezierPath()
    glossPath.move(to: CGPoint(x: glossRect.minX, y: glossRect.midY))
    glossPath.curve(to: CGPoint(x: glossRect.maxX, y: glossRect.maxY - 20),
                    controlPoint1: CGPoint(x: glossRect.minX + 70, y: glossRect.maxY + 40),
                    controlPoint2: CGPoint(x: glossRect.maxX - 120, y: glossRect.maxY + 10))
    glossPath.curve(to: CGPoint(x: glossRect.maxX - 28, y: glossRect.minY + 12),
                    controlPoint1: CGPoint(x: glossRect.maxX + 20, y: glossRect.maxY - 84),
                    controlPoint2: CGPoint(x: glossRect.maxX + 10, y: glossRect.minY + 36))
    glossPath.curve(to: CGPoint(x: glossRect.minX, y: glossRect.midY),
                    controlPoint1: CGPoint(x: glossRect.maxX - 140, y: glossRect.minY - 8),
                    controlPoint2: CGPoint(x: glossRect.minX + 44, y: glossRect.minY + 8))
    glossPath.close()
    context.addPath(glossPath.cgPath)
    context.clip()
    context.drawLinearGradient(gradient, start: CGPoint(x: glossRect.minX, y: glossRect.maxY), end: CGPoint(x: glossRect.maxX, y: glossRect.minY), options: [])
    context.restoreGState()
}

func path(_ points: [CGPoint]) -> NSBezierPath {
    let shape = NSBezierPath()
    guard let first = points.first else { return shape }
    shape.move(to: first)
    points.dropFirst().forEach { shape.line(to: $0) }
    shape.close()
    return shape
}

extension NSBezierPath {
    var cgPath: CGPath {
        let path = CGMutablePath()
        var points = [NSPoint](repeating: .zero, count: 3)

        for index in 0..<elementCount {
            switch element(at: index, associatedPoints: &points) {
            case .moveTo:
                path.move(to: points[0])
            case .lineTo:
                path.addLine(to: points[0])
            case .curveTo:
                path.addCurve(to: points[2], control1: points[0], control2: points[1])
            case .cubicCurveTo:
                path.addCurve(to: points[2], control1: points[0], control2: points[1])
            case .quadraticCurveTo:
                path.addQuadCurve(to: points[1], control: points[0])
            case .closePath:
                path.closeSubpath()
            @unknown default:
                break
            }
        }

        return path
    }
}
