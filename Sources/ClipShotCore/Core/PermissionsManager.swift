import Foundation
import AppKit
import CoreGraphics
import UserNotifications
import Combine

/// Manages macOS system permissions checking and deep linking to System Settings.
///
/// Handles Transparency, Consent, and Control (TCC) system checks for:
/// - Files and Folders: Read/write access to the designated screenshots folder.
/// - Screen Recording: ScreenCaptureKit and CoreGraphics capture access via `CGPreflightScreenCaptureAccess()`.
/// - User Notifications: Banner and sound delivery authorization via `UNUserNotificationCenter`.
public final class PermissionsManager: ObservableObject {
    /// Shared singleton instance for centralized permission queries across UI and background engines.
    public static let shared = PermissionsManager()

    /// Published flag indicating whether the app can read from the designated screenshot folder.
    @Published public var hasFolderAccess: Bool = true

    /// Published flag indicating whether the app has been granted Screen Recording permissions.
    @Published public var hasScreenRecordingAccess: Bool = false

    /// Published flag indicating whether the user has authorized local system notifications.
    @Published public var hasNotificationAccess: Bool = false

    /// Initializes the manager and runs a comprehensive preflight check on all permission domains.
    public init() {
        checkAllPermissions()
    }

    /// Evaluates folder access, screen recording access, and notification authorization in sequence.
    public func checkAllPermissions() {
        checkFolderAccess()
        checkScreenRecordingAccess()
        checkNotificationAccess()
    }

    /// Checks read accessibility for the active screenshot storage directory.
    public func checkFolderAccess() {
        let activeFolder = PathUtils.shared.activeScreenshotFolder()
        self.hasFolderAccess = PathUtils.shared.canReadFolder(at: activeFolder)
    }

    /// Evaluates whether the process has been granted macOS Screen Capture entitlements.
    ///
    /// Uses CoreGraphics `CGPreflightScreenCaptureAccess()` on macOS 10.15+ without triggering
    /// an intrusive user prompt.
    public func checkScreenRecordingAccess() {
        if #available(macOS 10.15, *) {
            self.hasScreenRecordingAccess = CGPreflightScreenCaptureAccess()
        } else {
            self.hasScreenRecordingAccess = true
        }
    }

    /// Triggers the native macOS system authorization prompt requesting Screen Capture privileges.
    ///
    /// Re-evaluates access status on the main queue after a brief 1-second delay to catch immediate approval.
    public func requestScreenRecordingAccess() {
        if #available(macOS 10.15, *) {
            CGRequestScreenCaptureAccess()
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.checkScreenRecordingAccess()
            }
        }
    }

    /// Queries the user notification authorization settings asynchronously.
    ///
    /// Guards against invocation in headless CLI / test runners lacking a valid `.app` bundle.
    public func checkNotificationAccess() {
        // UNUserNotificationCenter requires a valid .app bundle host; skip in xctest / CLI runners
        guard Bundle.main.bundleURL.pathExtension == "app" else { return }
        UNUserNotificationCenter.current().getNotificationSettings { [weak self] settings in
            DispatchQueue.main.async {
                self?.hasNotificationAccess = (settings.authorizationStatus == .authorized)
            }
        }
    }

    /// Requests user authorization to display alert banners, play audio badges, and badge the app icon.
    public func requestNotificationAccess() {
        guard Bundle.main.bundleURL.pathExtension == "app" else { return }
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { [weak self] granted, _ in
            DispatchQueue.main.async {
                self?.hasNotificationAccess = granted
            }
        }
    }

    // MARK: - Deep Links to System Settings

    /// Launches System Settings directly to the Screen & System Audio Recording privacy pane.
    public func openScreenRecordingSettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture") {
            NSWorkspace.shared.open(url)
        }
    }

    /// Launches System Settings directly to the Files and Folders privacy pane.
    public func openFolderAccessSettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_FilesAndFolders") {
            NSWorkspace.shared.open(url)
        }
    }

    /// Launches System Settings directly to the Notifications configuration pane.
    public func openNotificationSettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.notifications") {
            NSWorkspace.shared.open(url)
        }
    }
}
