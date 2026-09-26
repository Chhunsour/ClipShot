import XCTest
@testable import ClipShotCore

final class PermissionsManagerTests: XCTestCase {

    func testPermissionsManagerSingleton() {
        let manager = PermissionsManager.shared
        XCTAssertNotNil(manager)
    }

    func testCheckAllPermissionsDoesNotCrash() {
        let manager = PermissionsManager.shared
        manager.checkAllPermissions()
        manager.checkFolderAccess()
        manager.checkScreenRecordingAccess()
        manager.checkNotificationAccess()
    }
}
