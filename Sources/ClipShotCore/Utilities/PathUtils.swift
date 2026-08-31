import Foundation
import AppKit

/// Utilities for detecting and managing macOS screenshot folder locations and security bookmarks.
public final class PathUtils: @unchecked Sendable {
    public static let shared = PathUtils()

    /// Returns the active screenshot directory based on system defaults or user preference.
    public func activeScreenshotFolder() -> URL {
        let settings = AppSettings.shared

        // 1. Check user custom folder override
        if let customPath = settings.customScreenshotFolderPath, !customPath.isEmpty {
            // Check if bookmark exists
            if let bookmarkData = settings.screenshotFolderBookmark {
                var isStale = false
                if let url = try? URL(resolvingBookmarkData: bookmarkData, options: .withSecurityScope, relativeTo: nil, bookmarkDataIsStale: &isStale) {
                    if !isStale && FileManager.default.fileExists(atPath: url.path) {
                        _ = url.startAccessingSecurityScopedResource()
                        return url
                    }
                }
            }

            let customURL = URL(fileURLWithPath: (customPath as NSString).expandingTildeInPath)
            if FileManager.default.fileExists(atPath: customURL.path) {
                return customURL
            }
        }

        // 2. Detect system default screenshot location from com.apple.screencapture
        return detectSystemScreenshotFolder()
    }

    /// Reads `com.apple.screencapture location` via CFPreferences / UserDefaults.
    public func detectSystemScreenshotFolder() -> URL {
        if let location = CFPreferencesCopyAppValue("location" as CFString, "com.apple.screencapture" as CFString) as? String {
            let expanded = (location as NSString).expandingTildeInPath
            let url = URL(fileURLWithPath: expanded)
            if FileManager.default.fileExists(atPath: url.path) {
                return url
            }
        }

        // Standard macOS default is Desktop
        let desktop = FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: (("~/Desktop" as NSString).expandingTildeInPath))
        return desktop
    }

    /// Creates and saves a security-scoped bookmark for a selected folder URL.
    public func saveBookmark(for folderURL: URL) {
        do {
            let bookmark = try folderURL.bookmarkData(
                options: .withSecurityScope,
                includingResourceValuesForKeys: nil,
                relativeTo: nil
            )
            AppSettings.shared.screenshotFolderBookmark = bookmark
            AppSettings.shared.customScreenshotFolderPath = folderURL.path
            AppLogger.shared.info("Saved security-scoped bookmark for folder: \(folderURL.path)")
        } catch {
            AppSettings.shared.customScreenshotFolderPath = folderURL.path
            AppLogger.shared.warning("Failed to create security-scoped bookmark: \(error.localizedDescription)")
        }
    }

    /// Tests whether the application can read from the given folder.
    public func canReadFolder(at url: URL) -> Bool {
        var isDir: ObjCBool = false
        guard FileManager.default.fileExists(atPath: url.path, isDirectory: &isDir), isDir.boolValue else {
            return false
        }
        return FileManager.default.isReadableFile(atPath: url.path)
    }

    /// Returns a user-friendly display path (e.g. replacing $HOME with ~).
    public func displayPath(for url: URL) -> String {
        let home = NSHomeDirectory()
        let path = url.path
        if path.hasPrefix(home) {
            return "~" + path.dropFirst(home.count)
        }
        return path
    }
}
