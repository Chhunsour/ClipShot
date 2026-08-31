import Cocoa
import CoreGraphics

func renderIcon(size: CGFloat) -> NSImage {
    let image = NSImage(size: NSSize(width: size, height: size))
    image.lockFocus()

    guard let ctx = NSGraphicsContext.current?.cgContext else {
        image.unlockFocus()
        return image
    }

    let rect = CGRect(x: 0, y: 0, width: size, height: size)

    // Background Squircle with subtle gradient
    let cornerRadius = size * 0.224
    let squirclePath = CGPath(roundedRect: rect.insetBy(dx: size * 0.04, dy: size * 0.04), cornerWidth: cornerRadius, cornerHeight: cornerRadius, transform: nil)

    ctx.saveGState()
    ctx.addPath(squirclePath)
    ctx.clip()

    // Gradient: Deep Sapphire Blue to Electric Indigo
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    let colors = [
        NSColor(calibratedRed: 0.10, green: 0.35, blue: 0.85, alpha: 1.0).cgColor,
        NSColor(calibratedRed: 0.25, green: 0.15, blue: 0.70, alpha: 1.0).cgColor
    ] as CFArray
    let gradient = CGGradient(colorsSpace: colorSpace, colors: colors, locations: [0.0, 1.0])!
    ctx.drawLinearGradient(gradient, start: CGPoint(x: size * 0.5, y: size * 0.95), end: CGPoint(x: size * 0.5, y: size * 0.05), options: [])

    // Subtle top gloss highlight
    let glossPath = CGPath(roundedRect: CGRect(x: size * 0.06, y: size * 0.5, width: size * 0.88, height: size * 0.42), cornerWidth: cornerRadius * 0.8, cornerHeight: cornerRadius * 0.8, transform: nil)
    ctx.addPath(glossPath)
    ctx.setFillColor(NSColor.white.withAlphaComponent(0.12).cgColor)
    ctx.fillPath()

    ctx.restoreGState()

    // Border around icon
    ctx.saveGState()
    ctx.addPath(squirclePath)
    ctx.setStrokeColor(NSColor.white.withAlphaComponent(0.25).cgColor)
    ctx.setLineWidth(size * 0.015)
    ctx.strokePath()
    ctx.restoreGState()

    // Foreground Graphic: Viewfinder Corners + Clipboard Sheet
    ctx.saveGState()

    let innerMargin = size * 0.22
    let innerRect = rect.insetBy(dx: innerMargin, dy: innerMargin)
    let cornerLen = innerRect.width * 0.28
    let strokeW = size * 0.045

    ctx.setStrokeColor(NSColor.white.cgColor)
    ctx.setLineWidth(strokeW)
    ctx.setLineCap(.round)
    ctx.setLineJoin(.round)

    // Top-Left Corner
    ctx.beginPath()
    ctx.move(to: CGPoint(x: innerRect.minX, y: innerRect.maxY - cornerLen))
    ctx.addLine(to: CGPoint(x: innerRect.minX, y: innerRect.maxY))
    ctx.addLine(to: CGPoint(x: innerRect.minX + cornerLen, y: innerRect.maxY))
    ctx.strokePath()

    // Top-Right Corner
    ctx.beginPath()
    ctx.move(to: CGPoint(x: innerRect.maxX - cornerLen, y: innerRect.maxY))
    ctx.addLine(to: CGPoint(x: innerRect.maxX, y: innerRect.maxY))
    ctx.addLine(to: CGPoint(x: innerRect.maxX, y: innerRect.maxY - cornerLen))
    ctx.strokePath()

    // Bottom-Left Corner
    ctx.beginPath()
    ctx.move(to: CGPoint(x: innerRect.minX, y: innerRect.minY + cornerLen))
    ctx.addLine(to: CGPoint(x: innerRect.minX, y: innerRect.minY))
    ctx.addLine(to: CGPoint(x: innerRect.minX + cornerLen, y: innerRect.minY))
    ctx.strokePath()

    // Bottom-Right Corner
    ctx.beginPath()
    ctx.move(to: CGPoint(x: innerRect.maxX - cornerLen, y: innerRect.minY))
    ctx.addLine(to: CGPoint(x: innerRect.maxX, y: innerRect.minY))
    ctx.addLine(to: CGPoint(x: innerRect.maxX, y: innerRect.minY + cornerLen))
    ctx.strokePath()

    // Center: Clipboard / Flash Symbol
    let center = CGPoint(x: rect.midX, y: rect.midY)
    let boltW = size * 0.16
    let boltH = size * 0.26

    // Lightning Bolt / Instant Copy Spark
    ctx.beginPath()
    ctx.move(to: CGPoint(x: center.x + boltW * 0.2, y: center.y + boltH * 0.5))
    ctx.addLine(to: CGPoint(x: center.x - boltW * 0.5, y: center.y - boltH * 0.05))
    ctx.addLine(to: CGPoint(x: center.x + boltW * 0.05, y: center.y - boltH * 0.05))
    ctx.addLine(to: CGPoint(x: center.x - boltW * 0.2, y: center.y - boltH * 0.5))
    ctx.addLine(to: CGPoint(x: center.x + boltW * 0.5, y: center.y + boltH * 0.05))
    ctx.addLine(to: CGPoint(x: center.x - boltW * 0.05, y: center.y + boltH * 0.05))
    ctx.closePath()

    ctx.setFillColor(NSColor(calibratedRed: 1.0, green: 0.85, blue: 0.2, alpha: 1.0).cgColor)
    ctx.setShadow(offset: CGSize(width: 0, height: -2), blur: size * 0.04, color: NSColor.black.withAlphaComponent(0.4).cgColor)
    ctx.fillPath()

    ctx.restoreGState()
    image.unlockFocus()
    return image
}

let iconsetDir = URL(fileURLWithPath: "AppIcon.iconset")
try? FileManager.default.createDirectory(at: iconsetDir, withIntermediateDirectories: true)

let sizes: [(name: String, size: CGFloat)] = [
    ("icon_16x16.png", 16),
    ("icon_16x16@2x.png", 32),
    ("icon_32x32.png", 32),
    ("icon_32x32@2x.png", 64),
    ("icon_128x128.png", 128),
    ("icon_128x128@2x.png", 256),
    ("icon_256x256.png", 256),
    ("icon_256x256@2x.png", 512),
    ("icon_512x512.png", 512),
    ("icon_512x512@2x.png", 1024)
]

for item in sizes {
    let img = renderIcon(size: item.size)
    if let tiff = img.tiffRepresentation,
       let rep = NSBitmapImageRep(data: tiff),
       let png = rep.representation(using: .png, properties: [:]) {
        let fileURL = iconsetDir.appendingPathComponent(item.name)
        try? png.write(to: fileURL)
    }
}

print("Iconset generated successfully.")
