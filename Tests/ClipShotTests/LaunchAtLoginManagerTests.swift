import XCTest
@testable import ClipShotCore

final class LaunchAtLoginManagerTests: XCTestCase {

    func testLaunchAtLoginManagerSingleton() {
        let manager = LaunchAtLoginManager.shared
        XCTAssertNotNil(manager)
    }

    func testRefreshStatusDoesNotCrash() {
        let manager = LaunchAtLoginManager.shared
        manager.refreshStatus()
        // In unbundled test runner environment, service status defaults to notRegistered (isEnabled = false)
        XCTAssertFalse(manager.isEnabled)
    }
}
