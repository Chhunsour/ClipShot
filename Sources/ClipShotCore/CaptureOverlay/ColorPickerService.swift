import Foundation
import AppKit

/// Service for sampling, formatting, and copying screen pixel colors.
public final class ColorPickerService: @unchecked Sendable {
    public static let shared = ColorPickerService()

    public init() {}

    /// Samples the color at a global screen point and formats it according to settings.
    public func sampleAndFormat(at point: CGPoint, format: ColorFormat = AppSettings.shared.colorPickerFormat) -> (color: NSColor, formattedString: String)? {
        guard let color = ScreenCaptureEngine.shared.sampleColor(at: point) else { return nil }

        let formatted: String
        switch format {
        case .hex:
            formatted = hexString(from: color)
        case .rgb:
            formatted = rgbString(from: color)
        case .hsl:
            formatted = hslString(from: color)
        case .displayP3:
            formatted = displayP3String(from: color)
        }

        return (color, formatted)
    }

    /// Copies the sampled color string to clipboard and saves to recent colors.
    public func copyColor(at point: CGPoint, format: ColorFormat = AppSettings.shared.colorPickerFormat) -> String? {
        guard let (_, formatted) = sampleAndFormat(at: point, format: format) else { return nil }

        DispatchQueue.main.async {
            ClipboardManager.shared.copyText(formatted)
            AppSettings.shared.addRecentColor(formatted)
            SoundManager.shared.playCopySound()
        }

        return formatted
    }

    // MARK: - Color Formatters

    public func hexString(from color: NSColor) -> String {
        guard let rgb = color.usingColorSpace(.sRGB) else { return "#000000" }
        let r = Int(round(rgb.redComponent * 255))
        let g = Int(round(rgb.greenComponent * 255))
        let b = Int(round(rgb.blueComponent * 255))
        return String(format: "#%02X%02X%02X", r, g, b)
    }

    public func rgbString(from color: NSColor) -> String {
        guard let rgb = color.usingColorSpace(.sRGB) else { return "rgb(0, 0, 0)" }
        let r = Int(round(rgb.redComponent * 255))
        let g = Int(round(rgb.greenComponent * 255))
        let b = Int(round(rgb.blueComponent * 255))
        return "rgb(\(r), \(g), \(b))"
    }

    public func hslString(from color: NSColor) -> String {
        guard let rgb = color.usingColorSpace(.sRGB) else { return "hsl(0°, 0%, 0%)" }
        let h = Int(round(rgb.hueComponent * 360))
        let s = Int(round(rgb.saturationComponent * 100))
        let l = Int(round(rgb.brightnessComponent * 100))
        return "hsl(\(h)°, \(s)%, \(l)%)"
    }

    public func displayP3String(from color: NSColor) -> String {
        guard let p3 = color.usingColorSpace(.displayP3) else { return "color(display-p3 0 0 0)" }
        let r = String(format: "%.3f", p3.redComponent)
        let g = String(format: "%.3f", p3.greenComponent)
        let b = String(format: "%.3f", p3.blueComponent)
        return "color(display-p3 \(r) \(g) \(b))"
    }
}
