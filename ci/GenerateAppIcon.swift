import AppKit
import Foundation

private let canvasSize = 1024
private let outputURL: URL = {
    if CommandLine.arguments.count > 1 {
        return URL(fileURLWithPath: CommandLine.arguments[1])
    }
    return URL(fileURLWithPath: "KeepMeter/Assets.xcassets/AppIcon.appiconset/AppIcon.png")
}()

private func color(_ red: CGFloat, _ green: CGFloat, _ blue: CGFloat, alpha: CGFloat = 1) -> CGColor {
    NSColor(calibratedRed: red, green: green, blue: blue, alpha: alpha).cgColor
}

private func point(onCircle center: CGPoint, radius: CGFloat, degrees: CGFloat) -> CGPoint {
    let radians = degrees * .pi / 180
    return CGPoint(
        x: center.x + cos(radians) * radius,
        y: center.y + sin(radians) * radius
    )
}

try FileManager.default.createDirectory(
    at: outputURL.deletingLastPathComponent(),
    withIntermediateDirectories: true
)

// App Store icons must be fully opaque. A 3-channel bitmap guarantees that the
// generated PNG has no alpha channel while still allowing translucent drawing
// operations to be composited onto the opaque background.
guard let bitmap = NSBitmapImageRep(
    bitmapDataPlanes: nil,
    pixelsWide: canvasSize,
    pixelsHigh: canvasSize,
    bitsPerSample: 8,
    samplesPerPixel: 3,
    hasAlpha: false,
    isPlanar: false,
    colorSpaceName: .deviceRGB,
    bytesPerRow: 0,
    bitsPerPixel: 24
), let graphics = NSGraphicsContext(bitmapImageRep: bitmap) else {
    fputs("Unable to create KeepMeter icon bitmap.\n", stderr)
    exit(1)
}

NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = graphics
let context = graphics.cgContext
context.setAllowsAntialiasing(true)
context.setShouldAntialias(true)

let bounds = CGRect(x: 0, y: 0, width: canvasSize, height: canvasSize)

// Brand background: KeepMeter blue -> soft blue, matching KMTheme.
let colorSpace = CGColorSpaceCreateDeviceRGB()
let backgroundGradient = CGGradient(
    colorsSpace: colorSpace,
    colors: [
        color(0.105, 0.255, 0.745),
        color(0.19, 0.42, 0.96),
        color(0.39, 0.63, 1.00)
    ] as CFArray,
    locations: [0.0, 0.55, 1.0]
)!
context.drawLinearGradient(
    backgroundGradient,
    start: CGPoint(x: 110, y: 930),
    end: CGPoint(x: 930, y: 80),
    options: []
)

// Soft center glow keeps the symbol readable without introducing extra brand colors.
let glowGradient = CGGradient(
    colorsSpace: colorSpace,
    colors: [color(1, 1, 1, alpha: 0.16), color(1, 1, 1, alpha: 0.0)] as CFArray,
    locations: [0.0, 1.0]
)!
context.drawRadialGradient(
    glowGradient,
    startCenter: CGPoint(x: 510, y: 520),
    startRadius: 30,
    endCenter: CGPoint(x: 510, y: 520),
    endRadius: 470,
    options: []
)

let meterCenter = CGPoint(x: 470, y: 400)
let meterRadius: CGFloat = 300

// Main decision meter arc.
context.saveGState()
context.setLineCap(.round)
context.setLineWidth(92)
context.setStrokeColor(color(1, 1, 1, alpha: 0.93))
context.addArc(
    center: meterCenter,
    radius: meterRadius,
    startAngle: 210 * .pi / 180,
    endAngle: -30 * .pi / 180,
    clockwise: true
)
context.strokePath()

// Positive KEEP zone. Green is reserved for the positive decision state in-product.
context.setLineWidth(94)
context.setStrokeColor(color(0.13, 0.66, 0.43))
context.addArc(
    center: meterCenter,
    radius: meterRadius,
    startAngle: 33 * .pi / 180,
    endAngle: -30 * .pi / 180,
    clockwise: true
)
context.strokePath()
context.restoreGState()

// Needle: points into the KEEP zone. The white/blue hub keeps the symbol crisp at 60 px.
let needleAngle: CGFloat = 34
let needleEnd = point(onCircle: meterCenter, radius: 235, degrees: needleAngle)
context.saveGState()
context.setLineCap(.round)
context.setLineWidth(56)
context.setStrokeColor(color(1, 1, 1))
context.move(to: meterCenter)
context.addLine(to: needleEnd)
context.strokePath()

context.setFillColor(color(1, 1, 1))
context.fillEllipse(in: CGRect(x: meterCenter.x - 68, y: meterCenter.y - 68, width: 136, height: 136))
context.setFillColor(color(0.19, 0.42, 0.96))
context.fillEllipse(in: CGRect(x: meterCenter.x - 28, y: meterCenter.y - 28, width: 56, height: 56))
context.restoreGState()

// Compact confirmation badge: clear positive decision without shopping/receipt clichés.
let badgeCenter = CGPoint(x: 740, y: 665)
let badgeRadius: CGFloat = 112
context.saveGState()
context.setShadow(offset: CGSize(width: 0, height: -10), blur: 28, color: color(0.03, 0.12, 0.28, alpha: 0.24))
context.setFillColor(color(0.13, 0.66, 0.43))
context.fillEllipse(in: CGRect(
    x: badgeCenter.x - badgeRadius,
    y: badgeCenter.y - badgeRadius,
    width: badgeRadius * 2,
    height: badgeRadius * 2
))
context.restoreGState()

context.saveGState()
context.setLineCap(.round)
context.setLineJoin(.round)
context.setLineWidth(44)
context.setStrokeColor(color(1, 1, 1))
context.move(to: CGPoint(x: 680, y: 665))
context.addLine(to: CGPoint(x: 726, y: 620))
context.addLine(to: CGPoint(x: 810, y: 710))
context.strokePath()
context.restoreGState()

// Tiny lower highlight gives the full-bleed icon depth while staying fully opaque.
let highlightGradient = CGGradient(
    colorsSpace: colorSpace,
    colors: [color(1, 1, 1, alpha: 0.0), color(1, 1, 1, alpha: 0.08)] as CFArray,
    locations: [0.0, 1.0]
)!
context.drawLinearGradient(
    highlightGradient,
    start: CGPoint(x: 512, y: 540),
    end: CGPoint(x: 512, y: 0),
    options: []
)

NSGraphicsContext.restoreGraphicsState()

bitmap.size = NSSize(width: canvasSize, height: canvasSize)
guard let png = bitmap.representation(using: .png, properties: [:]) else {
    fputs("Unable to encode KeepMeter AppIcon.png.\n", stderr)
    exit(1)
}

try png.write(to: outputURL, options: .atomic)
print("Generated KeepMeter AppIcon: \(outputURL.path) [1024x1024, opaque]")
