import Foundation
import AppKit
import CoreGraphics
import UserNotifications
import Combine

/// Manages macOS system permissions checking and deep linking to System Settings.
public final class PermissionsManager: ObservableObject {
    public static let shared = PermissionsManager()

    @Published public var hasFolderAccess: Bool = true
    @Published public var hasScreenRecordingAccess: Bool = false
    @Published public var hasNotificationAccess: Bool = false

    public init() {
        checkAllPermissions()
    }

    public func checkAllPermissions() {
        checkFolderAccess()
        checkScreenRecordingAccess()
        checkNotificationAccess()
    }

    public func checkFolderAccess() {
        let activeFolder = PathUtils.shared.activeScreenshotFolder()
        self.hasFolderAccess = PathUtils.shared.canReadFolder(at: activeFolder)
    }

    public func checkScreenRecordingAccess() {
        if #available(macOS 10.15, *) {
            self.hasScreenRecordingAccess = CGPreflightScreenCaptureAccess()
        } else {
            self.hasScreenRecordingAccess = true
        }
    }

    public func requestScreenRecordingAccess() {
        if #available(macOS 10.15, *) {
            CGRequestScreenCaptureAccess()
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.checkScreenRecordingAccess()
            }
        }
    }

    public func checkNotificationAccess() {
        UNUserNotificationCenter.current().getNotificationSettings { [weak self] settings in
            DispatchQueue.main.async {
                self?.hasNotificationAccess = (settings.authorizationStatus == .authorized)
            }
        }
    }

    public func requestNotificationAccess() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { [weak self] granted, _ in
            DispatchQueue.main.async {
                self?.hasNotificationAccess = granted
            }
        }
    }

    // MARK: - Deep Links to System Settings

    public func openScreenRecordingSettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture") {
            NSWorkspace.shared.open(url)
        }
    }

    public func openFolderAccessSettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_FilesAndFolders") {
            NSWorkspace.shared.open(url)
        }
    }

    public func openNotificationSettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.notifications") {
            NSWorkspace.shared.open(url)
        }
    }
}
