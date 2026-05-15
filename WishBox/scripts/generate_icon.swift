#!/usr/bin/env swift
/// Renders the Wishly app icon to a 1024×1024 PNG and writes it into the asset catalog.
/// Run from the repo root:  swift WishBox/scripts/generate_icon.swift
import AppKit

// AppKit needs a minimal application object to render SF Symbols.
NSApplication.shared.setActivationPolicy(.accessory)

let S = 1024

// ── Bitmap canvas ──────────────────────────────────────────────────────────
let rep = NSBitmapImageRep(
    bitmapDataPlanes: nil,
    pixelsWide: S, pixelsHigh: S,
    bitsPerSample: 8, samplesPerPixel: 4,
    hasAlpha: true, isPlanar: false,
    colorSpaceName: .deviceRGB,
    bytesPerRow: 0, bitsPerPixel: 0
)!

guard let gfxCtx = NSGraphicsContext(bitmapImageRep: rep) else {
    print("✗ Could not create NSGraphicsContext"); exit(1)
}
NSGraphicsContext.current = gfxCtx
let cg = gfxCtx.cgContext
let mid = CGFloat(S) / 2

// ── 1. Radial gradient background ─────────────────────────────────────────
//   Center: #6b21a8 (violet)  →  Edge: #1a0533 (indigo)
let cs = CGColorSpaceCreateDeviceRGB()
let violet = CGColor(red: 107/255, green: 33/255, blue: 168/255, alpha: 1)
let indigo  = CGColor(red: 26/255,  green: 5/255,  blue: 51/255,  alpha: 1)
let grad = CGGradient(colorsSpace: cs, colors: [violet, indigo] as CFArray, locations: nil)!
cg.drawRadialGradient(
    grad,
    startCenter: CGPoint(x: mid, y: mid), startRadius: 0,
    endCenter:   CGPoint(x: mid, y: mid), endRadius: CGFloat(S) * 0.72,
    options: [.drawsBeforeStartLocation, .drawsAfterEndLocation]
)

// ── 2. White glow ring (15% opacity) ──────────────────────────────────────
cg.setFillColor(CGColor(red: 1, green: 1, blue: 1, alpha: 0.15))
let glowR: CGFloat = CGFloat(S) * 0.56
cg.fillEllipse(in: CGRect(x: mid - glowR/2, y: mid - glowR/2, width: glowR, height: glowR))

// ── 3. SF Symbol "gift.fill" in white ─────────────────────────────────────
let ptSize: CGFloat = 480
let symCfg = NSImage.SymbolConfiguration(pointSize: ptSize, weight: .bold)
    .applying(NSImage.SymbolConfiguration(paletteColors: [.white]))

if let sym = NSImage(systemSymbolName: "gift.fill", accessibilityDescription: nil)?
    .withSymbolConfiguration(symCfg) {
    let sw = sym.size.width, sh = sym.size.height
    sym.draw(in: NSRect(x: mid - sw/2, y: mid - sh/2, width: sw, height: sh))
} else {
    print("⚠ Could not load SF Symbol — icon will lack the gift image")
}

// ── Export ─────────────────────────────────────────────────────────────────
let outPath = "WishBox/Wishly/Assets.xcassets/AppIcon.appiconset/AppIcon-1024.png"
guard let png = rep.representation(using: .png, properties: [:]) else {
    print("✗ PNG encoding failed"); exit(1)
}
do {
    try png.write(to: URL(fileURLWithPath: outPath))
    print("✓ Icon saved → \(outPath)")
} catch {
    print("✗ Write failed: \(error)"); exit(1)
}
