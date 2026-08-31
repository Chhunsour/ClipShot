import Foundation

/// Centralized configuration and branding constants for ClipShot.
/// Allows easy rebranding, versioning, and default adjustments.
public enum AppConfig {
    public static let appName = "ClipShot"
    public static let bundleIdentifier = "com.clipshot.ClipShot"
    public static let appVersion = "1.0.0"
    public static let buildNumber = "1"
    public static let copyright = "Copyright © 2026 ClipShot. All rights reserved."

    public static let logSubsystem = "com.clipshot.ClipShot"
    public static let maxLogFiles = 3
    public static let maxLogFileSize: Int64 = 2 * 1024 * 1024 // 2MB

    public static let defaultPreviewDuration: TimeInterval = 5.0
    public static let defaultHistoryLimit = 100
    public static let defaultRetentionDays = 30

    public static let minFileStabilityCheckMs: UInt64 = 15_000_000 // 15ms in nanoseconds
    public static let maxFileStabilityRetries = 10

    public static let recentEventCacheDuration: TimeInterval = 5.0

    public static let helpURL = URL(string: "https://github.com/clipshot/clipshot")
}
