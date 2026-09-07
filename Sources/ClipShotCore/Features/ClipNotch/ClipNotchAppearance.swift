import Foundation
import AppKit
import SwiftUI

/// Curated 3-color palettes driving the ClipNotch chromatic orbit, rail gradients, and idle glow.
public enum ClipNotchColorway: String, CaseIterable, Identifiable, Codable, Sendable {
    case prism = "Prism"
    case aurora = "Aurora"
    case ember = "Ember"
    case tidal = "Tidal"
    case cyberpunk = "Cyberpunk"
    case solaris = "Solaris"
    case matrix = "Matrix"
    case cosmic = "Cosmic"
    case synthwave = "Synthwave"
    case sakura = "Sakura"
    case arctic = "Arctic"
    case champagne = "Champagne"
    case monochrome = "Monochrome"
    case albumAura = "Album Aura"

    public var id: String { rawValue }

    /// Exact hex definitions for each palette stop.
    public var hexColors: [String] {
        switch self {
        case .prism:
            return ["#64D8FF", "#A78BFA", "#FB7185"]
        case .aurora:
            return ["#5EF2C2", "#39C6FF", "#7C83FF"]
        case .ember:
            return ["#FFB45E", "#FF6B7A", "#C86BFF"]
        case .tidal:
            return ["#4DE1E8", "#72A7FF", "#465BFF"]
        case .cyberpunk:
            return ["#00F5D4", "#F72585", "#7209B7"]
        case .solaris:
            return ["#FFD166", "#FF6B6B", "#D11149"]
        case .matrix:
            return ["#00FF87", "#60EFFF", "#0061FF"]
        case .cosmic:
            return ["#818CF8", "#C084FC", "#F472B6"]
        case .synthwave:
            return ["#FEE140", "#FA709A", "#9B51E0"]
        case .sakura:
            return ["#FF9A9E", "#FECFEF", "#A18CD1"]
        case .arctic:
            return ["#A1C4FD", "#C2E9FB", "#E0C3FC"]
        case .champagne:
            return ["#F6D365", "#FDA085", "#D4AF37"]
        case .monochrome:
            return ["#F5F7FA", "#AAB3C2", "#687386"]
        case .albumAura:
            return ArtworkPalette.fallbackHexColors
        }
    }

    /// The three colors parsed using the module's Color(hex:) initializer.
    public var colors: [Color] {
        if self == .albumAura {
            return SystemNowPlayingService.shared.artworkPalette.map(Color.init(nsColor:))
        }
        return hexColors.map { Color(hex: $0) }
    }

    /// Primary accent color (first stop) used for notch idle wash and active rail glow.
    public var primaryAccent: Color {
        colors[0]
    }

    /// Secondary accent color (middle stop).
    public var secondaryAccent: Color {
        colors[1]
    }

    /// Tertiary accent color (end stop).
    public var tertiaryAccent: Color {
        colors[2]
    }

    /// Soft jewel glint stop inserted between the third and first color in the orb orbit.
    public static let softWhiteGlint = Color(red: 247 / 255, green: 250 / 255, blue: 255 / 255)

    /// 5-stop chromatic angular gradient for the central music orb.
    public var orbGradient: AngularGradient {
        let paletteColors = colors
        return AngularGradient(
            gradient: Gradient(colors: [
                paletteColors[0],
                paletteColors[1],
                paletteColors[2],
                Self.softWhiteGlint,
                paletteColors[0]
            ]),
            center: .center
        )
    }

    /// Leading-to-trailing linear gradient for the media rail container stroke.
    public var railGradient: LinearGradient {
        LinearGradient(
            colors: colors,
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    /// Swatch gradient for settings preview buttons.
    public var swatchGradient: LinearGradient {
        LinearGradient(
            colors: colors,
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    /// Keeps Album Aura's hero control anchored to the artwork's strongest sampled color.
    public var controlGradient: LinearGradient {
        let palette = colors
        return LinearGradient(
            colors: self == .albumAura
                ? [palette[0], palette[0], palette[1]]
                : palette,
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

/// Extracts a small, vivid palette once per artwork change for Album Aura.
enum ArtworkPalette {
    static let fallbackHexColors = ["#59E1FF", "#8B7CFF", "#FF5EA8"]
    static let fallback = [
        NSColor(srgbRed: 0.35, green: 0.88, blue: 1.00, alpha: 1),
        NSColor(srgbRed: 0.55, green: 0.49, blue: 1.00, alpha: 1),
        NSColor(srgbRed: 1.00, green: 0.37, blue: 0.66, alpha: 1)
    ]

    private struct Bucket {
        var count = 0
        var red = 0.0
        var green = 0.0
        var blue = 0.0
    }

    static func colors(from image: NSImage) -> [NSColor] {
        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil),
              let context = CGContext(
                data: nil,
                width: 24,
                height: 24,
                bitsPerComponent: 8,
                bytesPerRow: 24 * 4,
                space: CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
              ),
              let data = context.data else { return fallback }

        context.interpolationQuality = .medium
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: 24, height: 24))

        let bytes = data.bindMemory(to: UInt8.self, capacity: 24 * 24 * 4)
        var buckets: [Int: Bucket] = [:]
        for index in stride(from: 0, to: 24 * 24 * 4, by: 4) {
            guard bytes[index + 3] > 96 else { continue }
            let red = Double(bytes[index]) / 255
            let green = Double(bytes[index + 1]) / 255
            let blue = Double(bytes[index + 2]) / 255
            let brightness = max(red, green, blue)
            guard brightness > 0.02, brightness < 0.99 else { continue }

            let key = (Int(red * 7) << 6) | (Int(green * 7) << 3) | Int(blue * 7)
            var bucket = buckets[key, default: Bucket()]
            bucket.count += 1
            bucket.red += red
            bucket.green += green
            bucket.blue += blue
            buckets[key] = bucket
        }

        let ranked = buckets.values.sorted { lhs, rhs in
            score(lhs) > score(rhs)
        }
        var result: [NSColor] = []
        for bucket in ranked {
            let color = polishedColor(bucket)
            guard result.allSatisfy({ distance(color, $0) > 0.18 }) else { continue }
            result.append(color)
            if result.count == 3 { return result }
        }

        guard let anchor = result.first else { return fallback }
        let rgb = anchor.usingColorSpace(.sRGB) ?? anchor
        while result.count < 3 {
            result.append(NSColor(
                hue: rgb.hueComponent,
                saturation: result.count == 1
                    ? max(0.28, rgb.saturationComponent * 0.82)
                    : min(1, rgb.saturationComponent * 1.08),
                brightness: result.count == 1
                    ? min(1, rgb.brightnessComponent + 0.14)
                    : max(0.44, rgb.brightnessComponent - 0.10),
                alpha: 1
            ))
        }
        return result
    }

    private static func score(_ bucket: Bucket) -> Double {
        let count = Double(bucket.count)
        let red = bucket.red / count
        let green = bucket.green / count
        let blue = bucket.blue / count
        let saturation = max(red, green, blue) - min(red, green, blue)
        let brightness = max(red, green, blue)
        return sqrt(count) * (0.3 + saturation * 1.7) * (0.55 + brightness)
    }

    private static func polishedColor(_ bucket: Bucket) -> NSColor {
        let count = CGFloat(bucket.count)
        let red = CGFloat(bucket.red) / count
        let green = CGFloat(bucket.green) / count
        let blue = CGFloat(bucket.blue) / count
        let source = NSColor(
            srgbRed: red,
            green: green,
            blue: blue,
            alpha: 1
        )
        return NSColor(
            hue: source.hueComponent,
            saturation: source.saturationComponent,
            brightness: min(0.96, max(0.46, source.brightnessComponent)),
            alpha: 1
        )
    }

    private static func distance(_ lhs: NSColor, _ rhs: NSColor) -> CGFloat {
        let left = lhs.usingColorSpace(.sRGB) ?? lhs
        let right = rhs.usingColorSpace(.sRGB) ?? rhs
        return hypot(hypot(left.redComponent - right.redComponent, left.greenComponent - right.greenComponent), left.blueComponent - right.blueComponent)
    }
}

/// Surface finishes adjusting the outer notch body gradient, specular border, and capsule surfaces.
public enum ClipNotchFinish: String, CaseIterable, Identifiable, Codable, Sendable {
    case obsidian = "Obsidian"
    case glass = "Glass"
    case bloom = "Bloom"
    case titanium = "Titanium"
    case neonAura = "Neon Aura"
    case frosted = "Frosted"

    public var id: String { rawValue }

    // MARK: - Outer Notch Body Tokens

    public var outerBaseColor: Color {
        switch self {
        case .obsidian:
            return Color.black
        case .glass:
            return Color(red: 14 / 255, green: 15 / 255, blue: 18 / 255)
        case .bloom:
            return Color.black
        case .titanium:
            return Color(red: 20 / 255, green: 21 / 255, blue: 24 / 255)
        case .neonAura:
            return Color(red: 10 / 255, green: 10 / 255, blue: 14 / 255)
        case .frosted:
            return Color(red: 28 / 255, green: 30 / 255, blue: 36 / 255)
        }
    }

    public var outerTopFill: Color {
        switch self {
        case .obsidian:
            return Color.black
        case .glass:
            return Color.white.opacity(0.045)
        case .bloom:
            return Color.black
        case .titanium:
            return Color.white.opacity(0.08)
        case .neonAura:
            return Color.white.opacity(0.02)
        case .frosted:
            return Color.white.opacity(0.12)
        }
    }

    public var outerBottomFill: Color {
        switch self {
        case .obsidian:
            return Color.white.opacity(0.022)
        case .glass:
            return Color.white.opacity(0.055)
        case .bloom:
            return Color.white.opacity(0.025)
        case .titanium:
            return Color.white.opacity(0.04)
        case .neonAura:
            return Color.white.opacity(0.06)
        case .frosted:
            return Color.white.opacity(0.07)
        }
    }

    public var specularBorderOpacity: Double {
        switch self {
        case .obsidian:
            return 0.06
        case .glass:
            return 0.14
        case .bloom:
            return 0.08
        case .titanium:
            return 0.22
        case .neonAura:
            return 0.35
        case .frosted:
            return 0.20
        }
    }

    public var specularFloatingBorderOpacity: Double {
        switch self {
        case .obsidian:
            return 0.14
        case .glass:
            return 0.24
        case .bloom:
            return 0.16
        case .titanium:
            return 0.32
        case .neonAura:
            return 0.45
        case .frosted:
            return 0.30
        }
    }

    public var radialWashMultiplier: Double {
        switch self {
        case .obsidian:
            return 1.0
        case .glass:
            return 0.85
        case .bloom:
            return 1.85
        case .titanium:
            return 1.15
        case .neonAura:
            return 2.5
        case .frosted:
            return 0.70
        }
    }

    // MARK: - Media Rail Surface Tokens

    public var activeMediaRailFillOpacity: Double {
        switch self {
        case .obsidian: return 0.07
        case .glass: return 0.12
        case .bloom: return 0.09
        case .titanium: return 0.14
        case .neonAura: return 0.16
        case .frosted: return 0.18
        }
    }

    public var inactiveMediaRailFillOpacity: Double {
        switch self {
        case .obsidian: return 0.035
        case .glass: return 0.065
        case .bloom: return 0.04
        case .titanium: return 0.07
        case .neonAura: return 0.08
        case .frosted: return 0.10
        }
    }

    public var activeRailStrokeOpacity: Double {
        switch self {
        case .obsidian: return 0.80
        case .glass: return 0.95
        case .bloom: return 1.00
        case .titanium: return 0.90
        case .neonAura: return 1.00
        case .frosted: return 0.85
        }
    }

    public var inactiveRailStrokeOpacity: Double {
        switch self {
        case .obsidian: return 0.30
        case .glass: return 0.45
        case .bloom: return 0.40
        case .titanium: return 0.35
        case .neonAura: return 0.55
        case .frosted: return 0.40
        }
    }

    public var activeMediaGlowOpacity: Double {
        switch self {
        case .obsidian: return 0.22
        case .glass: return 0.28
        case .bloom: return 0.50
        case .titanium: return 0.30
        case .neonAura: return 0.75
        case .frosted: return 0.25
        }
    }

    public var inactiveMediaGlowOpacity: Double {
        switch self {
        case .obsidian: return 0.0
        case .glass: return 0.0
        case .bloom: return 0.12
        case .titanium: return 0.05
        case .neonAura: return 0.30
        case .frosted: return 0.05
        }
    }

    public var mediaGlowRadius: CGFloat {
        switch self {
        case .obsidian: return 4
        case .glass: return 5
        case .bloom: return 7
        case .titanium: return 5
        case .neonAura: return 12
        case .frosted: return 6
        }
    }

    // MARK: - Clipboard Surface Tokens

    public func clipboardFillOpacity(isHovered: Bool) -> Double {
        if isHovered {
            switch self {
            case .obsidian: return 0.075
            case .glass: return 0.13
            case .bloom: return 0.085
            case .titanium: return 0.15
            case .neonAura: return 0.18
            case .frosted: return 0.20
            }
        } else {
            switch self {
            case .obsidian: return 0.035
            case .glass: return 0.065
            case .bloom: return 0.04
            case .titanium: return 0.07
            case .neonAura: return 0.09
            case .frosted: return 0.10
            }
        }
    }

    public func clipboardStrokeOpacity(isHovered: Bool) -> Double {
        if isHovered {
            switch self {
            case .obsidian: return 0.16
            case .glass: return 0.26
            case .bloom: return 0.20
            case .titanium: return 0.28
            case .neonAura: return 0.40
            case .frosted: return 0.32
            }
        } else {
            switch self {
            case .obsidian: return 0.075
            case .glass: return 0.12
            case .bloom: return 0.09
            case .titanium: return 0.14
            case .neonAura: return 0.20
            case .frosted: return 0.16
            }
        }
    }

    public func clipboardOrbFillOpacity(isHovered: Bool) -> Double {
        if isHovered {
            switch self {
            case .obsidian, .bloom: return 0.14
            case .glass: return 0.18
            case .titanium: return 0.20
            case .neonAura: return 0.24
            case .frosted: return 0.22
            }
        } else {
            switch self {
            case .obsidian, .bloom: return 0.075
            case .glass: return 0.10
            case .titanium: return 0.10
            case .neonAura: return 0.12
            case .frosted: return 0.12
            }
        }
    }
}

/// Motion personalities driving orbit speed, hover scaling, and spring physics.
public enum ClipNotchMotion: String, CaseIterable, Identifiable, Codable, Sendable {
    case calm = "Calm"
    case fluid = "Fluid"
    case snappy = "Snappy"
    case pulse = "Pulse"
    case bouncy = "Bouncy"

    public var id: String { rawValue }

    /// Full rotation duration (in seconds) of the chromatic orbit while media is playing.
    public var orbitDuration: Double {
        switch self {
        case .calm: return 5.0
        case .fluid: return 3.2
        case .snappy: return 1.8
        case .pulse: return 2.15
        case .bouncy: return 2.8
        }
    }

    /// Hover scale for the central music artwork/note orb.
    public var musicOrbHoverScale: CGFloat {
        switch self {
        case .calm: return 1.025
        case .fluid: return 1.04
        case .snappy: return 1.05
        case .pulse: return 1.07
        case .bouncy: return 1.12
        }
    }

    /// Hover scale for transport buttons (previous/next).
    public var transportHoverScale: CGFloat {
        switch self {
        case .calm: return 1.08
        case .fluid: return 1.12
        case .snappy: return 1.14
        case .pulse: return 1.16
        case .bouncy: return 1.22
        }
    }

    /// Hover scale for the clipboard capsule.
    public var clipboardHoverScale: CGFloat {
        switch self {
        case .calm: return 1.015
        case .fluid: return 1.025
        case .snappy: return 1.03
        case .pulse: return 1.035
        case .bouncy: return 1.06
        }
    }

    /// General spring response for orb interactions.
    public var springResponse: Double {
        switch self {
        case .calm: return 0.38
        case .fluid: return 0.30
        case .snappy: return 0.18
        case .pulse: return 0.24
        case .bouncy: return 0.36
        }
    }

    /// General spring damping fraction for orb interactions.
    public var springDampingFraction: Double {
        switch self {
        case .calm: return 0.86
        case .fluid: return 0.80
        case .snappy: return 0.84
        case .pulse: return 0.72
        case .bouncy: return 0.58
        }
    }

    /// Spring response for transport buttons.
    public var transportSpringResponse: Double {
        switch self {
        case .calm: return 0.35
        case .fluid: return 0.28
        case .snappy: return 0.18
        case .pulse: return 0.22
        case .bouncy: return 0.32
        }
    }

    /// Spring damping for transport buttons.
    public var transportSpringDamping: Double {
        switch self {
        case .calm: return 0.80
        case .fluid: return 0.72
        case .snappy: return 0.76
        case .pulse: return 0.65
        case .bouncy: return 0.52
        }
    }

    /// Spring response for the clipboard button.
    public var clipboardSpringResponse: Double {
        switch self {
        case .calm: return 0.40
        case .fluid: return 0.32
        case .snappy: return 0.20
        case .pulse: return 0.26
        case .bouncy: return 0.34
        }
    }

    /// Spring damping for the clipboard button.
    public var clipboardSpringDamping: Double {
        switch self {
        case .calm: return 0.88
        case .fluid: return 0.82
        case .snappy: return 0.82
        case .pulse: return 0.75
        case .bouncy: return 0.56
        }
    }
}
