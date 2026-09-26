import XCTest
@testable import ClipShotCore

final class AppearanceSettingTests: XCTestCase {

    func testAppearanceSettingCases() {
        XCTAssertEqual(AppearanceSetting.allCases.count, 3)
        XCTAssertEqual(AppearanceSetting.system.rawValue, "system")
        XCTAssertEqual(AppearanceSetting.light.rawValue, "light")
        XCTAssertEqual(AppearanceSetting.dark.rawValue, "dark")
    }

    func testTitlesAreDescriptive() {
        XCTAssertEqual(AppearanceSetting.system.title, "System")
        XCTAssertEqual(AppearanceSetting.light.title, "Light")
        XCTAssertEqual(AppearanceSetting.dark.title, "Dark")
    }
}
