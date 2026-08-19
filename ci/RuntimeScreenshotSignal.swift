import AppKit
import Foundation

private func fail(_ message: String) -> Never {
    fputs("Runtime screenshot signal failed: \(message)\n", stderr)
    exit(1)
}

guard CommandLine.arguments.count == 2 else {
    fail("expected one screenshot path")
}

let path = CommandLine.arguments[1]
guard
    let image = NSImage(contentsOfFile: path),
    let tiff = image.tiffRepresentation,
    let bitmap = NSBitmapImageRep(data: tiff)
else {
    fail("could not decode \(path)")
}

let width = bitmap.pixelsWide
let height = bitmap.pixelsHigh
guard width > 100, height > 100 else {
    fail("unexpected image dimensions \(width)x\(height)")
}

// Ignore the outer edges/status-bar area and sample the central app surface.
let xStart = max(0, width / 10)
let xEnd = min(width, width * 9 / 10)
let yStart = max(0, height / 5)
let yEnd = min(height, height * 4 / 5)
let step = max(1, min(width, height) / 120)

var sampleCount = 0
var nearBlackCount = 0
var minLuma = 255.0
var maxLuma = 0.0
var sum = 0.0
var sumSquares = 0.0

for y in stride(from: yStart, to: yEnd, by: step) {
    for x in stride(from: xStart, to: xEnd, by: step) {
        guard let color = bitmap.colorAt(x: x, y: y)?.usingColorSpace(.deviceRGB) else { continue }
        let r = Double(color.redComponent) * 255.0
        let g = Double(color.greenComponent) * 255.0
        let b = Double(color.blueComponent) * 255.0
        let luma = 0.2126 * r + 0.7152 * g + 0.0722 * b

        sampleCount += 1
        if luma < 10.0 { nearBlackCount += 1 }
        minLuma = min(minLuma, luma)
        maxLuma = max(maxLuma, luma)
        sum += luma
        sumSquares += luma * luma
    }
}

guard sampleCount > 100 else {
    fail("too few decoded samples: \(sampleCount)")
}

let count = Double(sampleCount)
let mean = sum / count
let variance = max(0.0, (sumSquares / count) - (mean * mean))
let standardDeviation = sqrt(variance)
let nearBlackRatio = Double(nearBlackCount) / count
let dynamicRange = maxLuma - minLuma

print(
    String(
        format: "Screenshot signal %@ — range %.1f, stddev %.1f, near-black %.1f%%",
        URL(fileURLWithPath: path).lastPathComponent,
        dynamicRange,
        standardDeviation,
        nearBlackRatio * 100.0
    )
)

if dynamicRange < 18.0 {
    fail("central app surface is visually near-uniform")
}

if nearBlackRatio > 0.97 && standardDeviation < 18.0 {
    fail("central app surface is effectively black")
}

print("✓ Runtime screenshot contains meaningful app visual signal")
