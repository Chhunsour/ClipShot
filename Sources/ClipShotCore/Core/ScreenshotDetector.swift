import Foundation
import CoreServices
import ImageIO

/// Identifies whether a newly detected file in the monitored directory is a valid macOS screenshot.
public final class ScreenshotDetector: Sendable {
    public static let shared = ScreenshotDetector()

    // Standard localized prefix patterns used by macOS for screenshots across languages
    private static let screenshotPrefixes: [String] = [
        "screen shot",
        "screenshot",
        "capture d’écran",
        "capture d'écran",
        "captura de pantalla",
        "bildschirmfoto",
        "schermata",
        "schermafbeelding",
        "skärmavbild",
        "skjermbilde",
        "skærmbillede",
        "näyttökuva",
        "zrzut ekranu",
        "snimka zaslona",
        "snip",
        "снимок экрана",
        "скріншот",
        "スクリーンショット",
        "截屏",
        "屏幕快照",
        "螢幕快照",
        "화면 캡처",
        "ภาพหน้าจอ",
        "tangkapan layar",
        "cleanshot",
        "simulator screenshot"
    ]

    public init() {}

    /// Determines whether the file at the given URL is a screenshot according to current settings.
    public func isScreenshot(url: URL, settings: AppSettings = .shared) -> Bool {
        // 1. Verify file exists and has a supported image extension
        guard ImageUtils.isImageFile(at: url) else { return false }

        let path = url.path
        let filename = url.lastPathComponent.lowercased()

        // 2. If detection mode is allImages, accept any recently created image
        if settings.detectionMode == .allImages {
            return isRecentlyCreated(path: path, maxAge: maxAge(for: settings.detectionSensitivity))
        }

        // 3. Fast path: Filename pattern matching (0.001ms, avoids slow Spotlight IPC)
        if matchesScreenshotNamingPattern(filename: filename) && isRecentlyCreated(path: path, maxAge: maxAge(for: settings.detectionSensitivity)) {
            return true
        }

        // 4. Fallback: Check macOS Spotlight / MDItem metadata for kMDItemIsScreenCapture
        if let isScreenCapture = checkMDItemIsScreenCapture(url: url), isScreenCapture {
            AppLogger.shared.debug("Screenshot confirmed via MDItem metadata: \(url.lastPathComponent)")
            return true
        }

        return false
    }

    /// Checks Spotlight MDItem metadata for `kMDItemIsScreenCapture`.
    public func checkMDItemIsScreenCapture(url: URL) -> Bool? {
        guard let mdItem = MDItemCreateWithURL(kCFAllocatorDefault, url as CFURL) else {
            return nil
        }

        if let isScreenCapture = MDItemCopyAttribute(mdItem, "kMDItemIsScreenCapture" as CFString) as? Bool {
            return isScreenCapture
        }

        return nil
    }

    /// Checks if a filename matches standard macOS screenshot naming conventions.
    public func matchesScreenshotNamingPattern(filename: String) -> Bool {
        let lower = filename.lowercased()

        // Check standard prefixes
        for prefix in Self.screenshotPrefixes {
            if lower.hasPrefix(prefix) {
                return true
            }
        }

        // Check date/time regex pattern: e.g. "2026-08-31 at 11.20.45" or "2026-08-31 11.20.45"
        let dateRegex = #"\d{4}[-_.]\d{2}[-_.]\d{2}"#
        if lower.range(of: dateRegex, options: .regularExpression) != nil && (lower.contains("screen") || lower.contains("shot") || lower.contains("capture") || lower.contains("at") || lower.contains("morning") || lower.contains("afternoon")) {
            return true
        }

        return false
    }

    /// Checks if the file was created or modified recently.
    public func isRecentlyCreated(path: String, maxAge: TimeInterval) -> Bool {
        guard let attrs = try? FileManager.default.attributesOfItem(atPath: path) else {
            return false
        }

        let now = Date()
        if let creationDate = attrs[.creationDate] as? Date {
            let age = abs(now.timeIntervalSince(creationDate))
            if age <= maxAge { return true }
        }

        if let modDate = attrs[.modificationDate] as? Date {
            let age = abs(now.timeIntervalSince(modDate))
            if age <= maxAge { return true }
        }

        return false
    }

    private func maxAge(for sensitivity: DetectionSensitivity) -> TimeInterval {
        switch sensitivity {
        case .strict: return 60.0
        case .balanced: return 180.0
        case .permissive: return 300.0
        }
    }
}
