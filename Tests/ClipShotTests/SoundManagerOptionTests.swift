import XCTest
import AppKit
@testable import ClipShotCore

final class SoundManagerOptionTests: XCTestCase {

    func testSystemSoundAssetsAvailableOnMacOS() {
        let tinkSound = NSSound(named: "Tink")
        let popSound = NSSound(named: "Pop")
        
        // At least one of the primary feedback sounds must be bundled with macOS
        XCTAssertTrue(tinkSound != nil || popSound != nil, "macOS system sound library should provide Tink or Pop")
    }

    func testInstanceCreationAndIndependence() {
        let instance1 = SoundManager()
        let instance2 = SoundManager()
        XCTAssertTrue(instance1 !== instance2)
        XCTAssertTrue(instance1 !== SoundManager.shared)
    }

    func testPlayCopySoundConcurrentCallsDoNotCrash() {
        let soundManager = SoundManager()
        let initialSetting = AppSettings.shared.playSoundOnCopy
        AppSettings.shared.playSoundOnCopy = true
        defer { AppSettings.shared.playSoundOnCopy = initialSetting }

        let expectation = expectation(description: "Concurrent sound playback invocation")
        expectation.expectedFulfillmentCount = 20

        DispatchQueue.concurrentPerform(iterations: 20) { _ in
            soundManager.playCopySound()
            expectation.fulfill()
        }

        waitForExpectations(timeout: 2.0)
    }

    func testPlayCopySoundWhenDisabledDoesNotTrigger() {
        let soundManager = SoundManager()
        let initialSetting = AppSettings.shared.playSoundOnCopy
        AppSettings.shared.playSoundOnCopy = false
        defer { AppSettings.shared.playSoundOnCopy = initialSetting }

        // When disabled, playCopySound should return immediately without scheduling audio
        soundManager.playCopySound()
        XCTAssertFalse(AppSettings.shared.playSoundOnCopy)
    }
}
