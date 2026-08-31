import Foundation
import AppKit

/// Manages feedback sound playback for screenshot capture & copy events.
public final class SoundManager: @unchecked Sendable {
    public static let shared = SoundManager()

    private let sound: NSSound?

    public init() {
        self.sound = NSSound(named: "Tink") ?? NSSound(named: "Pop")
    }

    /// Plays the subtle copy confirmation sound if enabled in user settings.
    public func playCopySound() {
        guard AppSettings.shared.playSoundOnCopy else { return }
        DispatchQueue.main.async { [weak self] in
            self?.sound?.stop()
            self?.sound?.play()
        }
    }
}
