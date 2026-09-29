import XCTest
import ServiceManagement
@testable import ClipShotCore

final class LaunchAtLoginManagerTests: XCTestCase {

    func testLaunchAtLoginManagerSingleton() {
        let manager = LaunchAtLoginManager.shared
        XCTAssertNotNil(manager)
    }

    func testRefreshStatusDoesNotCrash() {
        let manager = LaunchAtLoginManager.shared
        manager.refreshStatus()
        XCTAssertEqual(manager.isEnabled, SMAppService.mainApp.status == .enabled)
    }
}
