import XCTest
import CoreGraphics
@testable import ClipShotCore

final class PermissionsManagerStatusTests: XCTestCase {
    func testSystemSettingsDeepLinkURLs() {
        let screenCaptureURL = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture")
        XCTAssertNotNil(screenCaptureURL)
        XCTAssertEqual(screenCaptureURL?.scheme, "x-apple.systempreferences")
        XCTAssertTrue(screenCaptureURL?.query?.contains("Privacy_ScreenCapture") == true)

        let filesFoldersURL = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_FilesAndFolders")
        XCTAssertNotNil(filesFoldersURL)
        XCTAssertEqual(filesFoldersURL?.scheme, "x-apple.systempreferences")
        XCTAssertTrue(filesFoldersURL?.query?.contains("Privacy_FilesAndFolders") == true)

        let notificationsURL = URL(string: "x-apple.systempreferences:com.apple.preference.notifications")
        XCTAssertNotNil(notificationsURL)
        XCTAssertEqual(notificationsURL?.scheme, "x-apple.systempreferences")
    }

    func testScreenRecordingAccessMatchesSystemPreflight() {
        let manager = PermissionsManager.shared
        manager.checkScreenRecordingAccess()
        let expected = CGPreflightScreenCaptureAccess()
        XCTAssertEqual(manager.hasScreenRecordingAccess, expected)
    }

    func testFolderAccessEvaluatesActiveScreenshotDirectory() {
        let manager = PermissionsManager.shared
        manager.checkFolderAccess()
        let folder = PathUtils.shared.activeScreenshotFolder()
        let readable = PathUtils.shared.canReadFolder(at: folder)
        XCTAssertEqual(manager.hasFolderAccess, readable)
    }

    func testNotificationAccessBypassedInUnbundledHost() {
        let manager = PermissionsManager.shared
        // In xctest environment Bundle.main is not .app, so checkNotificationAccess returns safely
        manager.checkNotificationAccess()
        XCTAssertFalse(manager.hasNotificationAccess)
    }
}
