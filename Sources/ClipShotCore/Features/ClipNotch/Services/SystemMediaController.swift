import AppKit
import Darwin

public enum SystemMediaCommand: Int32, Sendable {
    case playPause = 16
    case next = 17
    case previous = 18
}

/// Sends the same system media-key events as the keyboard play/skip controls with seeking support.
public enum SystemMediaController {
    private typealias SendCommand = @convention(c) (Int, NSDictionary?) -> Bool
    private static let frameworkHandle = dlopen(
        "/System/Library/PrivateFrameworks/MediaRemote.framework/MediaRemote",
        RTLD_NOW
    )
    private static let sendCommand: SendCommand? = frameworkHandle
        .flatMap { dlsym($0, "MRMediaRemoteSendCommand") }
        .map { unsafeBitCast($0, to: SendCommand.self) }

    @discardableResult
    public static func send(_ command: SystemMediaCommand) -> Bool {
        sendCommand?(mediaRemoteValue(for: command), nil) ?? false
    }

    /// Sets playback position (in seconds).
    public static func seek(to seconds: Double) {
        let clampedSeconds = max(0, seconds)
        // 1. Send MediaRemote command 55 (kMRSetPlaybackPosition)
        let userInfo: NSDictionary = ["kMRMediaRemoteOptionPlaybackPosition": NSNumber(value: clampedSeconds)]
        _ = sendCommand?(55, userInfo)

        // 2. Also send AppleScript to active player apps if running
        DispatchQueue.global(qos: .userInitiated).async {
            let script = """
            if application "Music" is running then
                tell application "Music" to set player position to \(clampedSeconds)
            else if application "Spotify" is running then
                tell application "Spotify" to set player position to \(clampedSeconds)
            end if
            """
            if let appleScript = NSAppleScript(source: script) {
                var errorInfo: NSDictionary?
                appleScript.executeAndReturnError(&errorInfo)
            }
        }
    }

    /// Skips forward or backward by the specified number of seconds.
    public static func skip(seconds: Double, relativeTo current: Double, duration: Double) {
        let maxDuration = duration > 0 ? duration : Double.greatestFiniteMagnitude
        let target = max(0, min(current + seconds, maxDuration))
        seek(to: target)
    }

    /// Sets system audio output volume (0.0 to 1.0).
    public static func setVolume(_ volume: Double) {
        let volInt = Int(max(0, min(100, volume * 100)))
        DispatchQueue.global(qos: .userInitiated).async {
            let script = "set volume output volume \(volInt)"
            if let appleScript = NSAppleScript(source: script) {
                var err: NSDictionary?
                appleScript.executeAndReturnError(&err)
            }
        }
    }

    /// Gets current system audio output volume (0.0 to 1.0).
    public static func getVolume() -> Double {
        let script = "output volume of (get volume settings)"
        if let appleScript = NSAppleScript(source: script) {
            var err: NSDictionary?
            let result = appleScript.executeAndReturnError(&err)
            if err == nil {
                return Double(result.int32Value) / 100.0
            }
        }
        return 0.75
    }

    static func mediaRemoteValue(for command: SystemMediaCommand) -> Int {
        switch command {
        case .playPause: return 2
        case .next: return 4
        case .previous: return 5
        }
    }

    static func eventData(for command: SystemMediaCommand, keyDown: Bool) -> Int {
        (Int(command.rawValue) << 16) | ((keyDown ? 0xA : 0xB) << 8)
    }
}
