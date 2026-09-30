import Foundation
import AppKit

/// Utilities for detecting, validating, and managing macOS screenshot folder locations,
/// sandboxed file system security bookmarks, and user directory defaults.
///
/// Under macOS App Sandbox restrictions, file access outside standard application container
/// boundaries requires persistent security-scoped bookmarks granted via user consent (`NSOpenPanel`).
/// This utility coordinates bookmark retrieval, resolution, stale bookmark detection, and fallback
/// to native `com.apple.screencapture` preference domains.
public final class PathUtils: @unchecked Sendable {
    /// Shared singleton instance for thread-safe path resolution and preference synchronization.
    public static let shared = PathUtils()

    /// Returns the active screenshot directory based on system defaults or user preference.
    ///
    /// Resolution Order:
    /// 1. Security-scoped bookmark from user preferences (if configured and valid).
    ///    Calls `startAccessingSecurityScopedResource()` to activate the sandbox access grant.
    /// 2. User-configured custom folder path expanded from tilde (if accessible without sandbox restriction).
    /// 3. macOS system screenshot directory read directly from `com.apple.screencapture location`.
    /// 4. Fallback to `~/Desktop` in the current user domain.
    ///
    /// - Returns: A validated, reachable `URL` pointing to the designated screenshot folder.
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
    /// Falls back to the current user's `~/Desktop` directory if no preference is configured.
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
    /// - Parameter folderURL: File system directory URL chosen by the user in NSOpenPanel.
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
    /// - Parameter url: Target directory URL to inspect.
    /// - Returns: True if path exists, is a directory, and is readable by the app process.
    public func canReadFolder(at url: URL) -> Bool {
        var isDir: ObjCBool = false
        guard FileManager.default.fileExists(atPath: url.path, isDirectory: &isDir), isDir.boolValue else {
            return false
        }
        return FileManager.default.isReadableFile(atPath: url.path)
    }

    /// Returns a user-friendly display path replacing the user's home directory prefix with `~`.
    /// - Parameter url: Target file system URL.
    /// - Returns: Compact path string formatted for UI presentation.
    public func displayPath(for url: URL) -> String {
        let home = NSHomeDirectory()
        let path = url.path
        if path.hasPrefix(home) {
            return "~" + path.dropFirst(home.count)
        }
        return path
    }
}
