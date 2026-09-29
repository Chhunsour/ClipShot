import XCTest
import ServiceManagement
import Combine
@testable import ClipShotCore

final class LaunchAtLoginStatusTests: XCTestCase {
    func testLaunchAtLoginInstanceInitialization() {
        let manager = LaunchAtLoginManager()
        XCTAssertNotNil(manager)
    }

    func testPublishedPropertyEmitsOnRefresh() {
        let manager = LaunchAtLoginManager()
        var receivedValues: [Bool] = []
        var cancellables = Set<AnyCancellable>()

        manager.$isEnabled
            .sink { receivedValues.append($0) }
            .store(in: &cancellables)

        manager.refreshStatus()

        XCTAssertFalse(receivedValues.isEmpty)
    }

    func testSMAppServiceStatusMappingSimulation() {
        func mapStatus(_ status: SMAppService.Status) -> Bool {
            status == .enabled
        }

        XCTAssertTrue(mapStatus(.enabled))
        XCTAssertFalse(mapStatus(.notRegistered))
        XCTAssertFalse(mapStatus(.requiresApproval))
        XCTAssertFalse(mapStatus(.notFound))
    }

    func testToggleInvokesSafeLifecycle() {
        let manager = LaunchAtLoginManager()
        let initial = manager.isEnabled
        // Toggle once
        manager.toggle()
        XCTAssertNotEqual(manager.isEnabled, initial)
        // Toggle back to restore original state
        manager.toggle()
        XCTAssertEqual(manager.isEnabled, initial)
    }
}
