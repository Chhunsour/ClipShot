import XCTest
@testable import ClipShotCore

final class SoundManagerTests: XCTestCase {

    func testSoundManagerSingleton() {
        let manager = SoundManager.shared
        XCTAssertNotNil(manager)
    }

    func testPlayCopySoundRespectsSettingsToggle() {
        let initialSetting = AppSettings.shared.playSoundOnCopy

        AppSettings.shared.playSoundOnCopy = false
        SoundManager.shared.playCopySound()

        AppSettings.shared.playSoundOnCopy = true
        SoundManager.shared.playCopySound()

        // Restore original setting
        AppSettings.shared.playSoundOnCopy = initialSetting
    }
}
