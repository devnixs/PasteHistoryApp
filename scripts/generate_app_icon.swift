import AppKit
import Foundation

let fileManager = FileManager.default
let rootURL = URL(fileURLWithPath: CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : FileManager.default.currentDirectoryPath)
let packagingURL = rootURL.appendingPathComponent("Packaging", isDirectory: true)
let iconsetURL = packagingURL.appendingPathComponent("AppIcon.iconset", isDirectory: true)
let icnsURL = packagingURL.appendingPathComponent("AppIcon.icns", isDirectory: false)

let iconEntries: [(name: String, points: CGFloat, pixels: Int)] = [
    ("icon_16x16.png", 16, 16),
    ("icon_16x16@2x.png", 16, 32),
    ("icon_32x32.png", 32, 32),
    ("icon_32x32@2x.png", 32, 64),
    ("icon_128x128.png", 128, 128),
    ("icon_128x128@2x.png", 128, 256),
    ("icon_256x256.png", 256, 256),
    ("icon_256x256@2x.png", 256, 512),
    ("icon_512x512.png", 512, 512),
    ("icon_512x512@2x.png", 512, 1024)
]

try? fileManager.removeItem(at: iconsetURL)
try fileManager.createDirectory(at: iconsetURL, withIntermediateDirectories: true)

for entry in iconEntries {
    let image = try renderIcon(size: CGFloat(entry.pixels))
    let pngData = try pngData(for: image, pixels: entry.pixels)
    try pngData.write(to: iconsetURL.appendingPathComponent(entry.name), options: .atomic)
}

if fileManager.fileExists(atPath: icnsURL.path) {
    try fileManager.removeItem(at: icnsURL)
}

let process = Process()
process.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
process.arguments = ["-c", "icns", iconsetURL.path, "-o", icnsURL.path]
try process.run()
process.waitUntilExit()

guard process.terminationStatus == 0 else {
    throw NSError(domain: "AppIcon", code: Int(process.terminationStatus), userInfo: [
        NSLocalizedDescriptionKey: "iconutil failed with status \(process.terminationStatus)"
    ])
}

print("Generated \(icnsURL.path)")

func renderIcon(size: CGFloat) throws -> NSImage {
    let image = NSImage(size: NSSize(width: size, height: size))
    image.lockFocus()

    defer { image.unlockFocus() }

    let rect = NSRect(x: 0, y: 0, width: size, height: size)
    NSGraphicsContext.current?.imageInterpolation = .high

    let backgroundPath = NSBezierPath(roundedRect: rect, xRadius: size * 0.23, yRadius: size * 0.23)
    let gradient = NSGradient(colors: [
        NSColor(calibratedRed: 0.99, green: 0.42, blue: 0.28, alpha: 1.0),
        NSColor(calibratedRed: 0.98, green: 0.73, blue: 0.24, alpha: 1.0),
        NSColor(calibratedRed: 0.25, green: 0.78, blue: 0.74, alpha: 1.0)
    ])!
    gradient.draw(in: backgroundPath, angle: -45)

    NSColor.white.withAlphaComponent(0.16).setFill()
    let glow = NSBezierPath(ovalIn: NSRect(x: size * 0.1, y: size * 0.6, width: size * 0.8, height: size * 0.32))
    glow.fill()

    let shadow = NSShadow()
    shadow.shadowColor = NSColor.black.withAlphaComponent(0.18)
    shadow.shadowBlurRadius = size * 0.04
    shadow.shadowOffset = NSSize(width: 0, height: -size * 0.02)
    shadow.set()

    let boardRect = NSRect(x: size * 0.22, y: size * 0.17, width: size * 0.56, height: size * 0.64)
    let boardPath = NSBezierPath(roundedRect: boardRect, xRadius: size * 0.09, yRadius: size * 0.09)
    NSColor(calibratedWhite: 0.99, alpha: 0.96).setFill()
    boardPath.fill()

    let clipRect = NSRect(x: size * 0.37, y: size * 0.72, width: size * 0.26, height: size * 0.11)
    let clipPath = NSBezierPath(roundedRect: clipRect, xRadius: size * 0.05, yRadius: size * 0.05)
    NSColor(calibratedWhite: 0.9, alpha: 1.0).setFill()
    clipPath.fill()

    let paperRect = boardRect.insetBy(dx: size * 0.065, dy: size * 0.085)
    let paperPath = NSBezierPath(roundedRect: paperRect, xRadius: size * 0.05, yRadius: size * 0.05)
    NSColor.white.setFill()
    paperPath.fill()

    let accent = NSColor(calibratedRed: 0.17, green: 0.3, blue: 0.55, alpha: 1.0)
    accent.setStroke()

    let clockCenter = CGPoint(x: size * 0.44, y: size * 0.47)
    let clockRadius = size * 0.12
    let clockPath = NSBezierPath()
    clockPath.lineWidth = size * 0.028
    clockPath.appendArc(withCenter: clockCenter, radius: clockRadius, startAngle: 0, endAngle: 360)
    clockPath.stroke()

    let minuteHand = NSBezierPath()
    minuteHand.lineWidth = size * 0.028
    minuteHand.lineCapStyle = .round
    minuteHand.move(to: clockCenter)
    minuteHand.line(to: CGPoint(x: clockCenter.x, y: clockCenter.y + clockRadius * 0.55))
    minuteHand.stroke()

    let hourHand = NSBezierPath()
    hourHand.lineWidth = size * 0.028
    hourHand.lineCapStyle = .round
    hourHand.move(to: clockCenter)
    hourHand.line(to: CGPoint(x: clockCenter.x + clockRadius * 0.42, y: clockCenter.y))
    hourHand.stroke()

    let historyArc = NSBezierPath()
    historyArc.lineWidth = size * 0.03
    historyArc.lineCapStyle = .round
    historyArc.appendArc(withCenter: clockCenter, radius: clockRadius * 1.42, startAngle: 210, endAngle: 35)
    historyArc.stroke()

    let arrow = NSBezierPath()
    arrow.lineWidth = size * 0.03
    arrow.lineCapStyle = .round
    arrow.lineJoinStyle = .round
    let arrowTip = CGPoint(x: size * 0.56, y: size * 0.63)
    arrow.move(to: CGPoint(x: arrowTip.x - size * 0.04, y: arrowTip.y + size * 0.01))
    arrow.line(to: arrowTip)
    arrow.line(to: CGPoint(x: arrowTip.x - size * 0.005, y: arrowTip.y - size * 0.04))
    arrow.stroke()

    let sparkleColor = NSColor(calibratedRed: 0.96, green: 0.26, blue: 0.49, alpha: 1.0)
    sparkleColor.setStroke()
    drawSparkle(center: CGPoint(x: size * 0.66, y: size * 0.38), arm: size * 0.05, lineWidth: size * 0.02)
    drawSparkle(center: CGPoint(x: size * 0.61, y: size * 0.56), arm: size * 0.03, lineWidth: size * 0.016)

    return image
}

func drawSparkle(center: CGPoint, arm: CGFloat, lineWidth: CGFloat) {
    let path = NSBezierPath()
    path.lineWidth = lineWidth
    path.lineCapStyle = .round
    path.move(to: CGPoint(x: center.x, y: center.y - arm))
    path.line(to: CGPoint(x: center.x, y: center.y + arm))
    path.move(to: CGPoint(x: center.x - arm, y: center.y))
    path.line(to: CGPoint(x: center.x + arm, y: center.y))
    path.stroke()
}

func pngData(for image: NSImage, pixels: Int) throws -> Data {
    guard
        let tiffData = image.tiffRepresentation,
        let bitmap = NSBitmapImageRep(data: tiffData)
    else {
        throw NSError(domain: "AppIcon", code: 1, userInfo: [NSLocalizedDescriptionKey: "Could not create bitmap image representation"])
    }

    bitmap.size = NSSize(width: pixels, height: pixels)

    guard let pngData = bitmap.representation(using: .png, properties: [:]) else {
        throw NSError(domain: "AppIcon", code: 2, userInfo: [NSLocalizedDescriptionKey: "Could not encode PNG data"])
    }

    return pngData
}
