import AppKit
import Darwin

public enum SystemMediaCommand: Int32, Sendable {
    case playPause = 16
    case next = 17
    case previous = 18
}

public enum SystemMediaOption: Sendable {
    case shuffle
    case repeatMode
    case favorite
}

public struct SystemMediaPlaybackOptions: Equatable, Sendable {
    public let shuffle: Bool
    public let repeatEnabled: Bool
    public let favorite: Bool
    public let shuffleAvailable: Bool
    public let repeatAvailable: Bool
    public let favoriteAvailable: Bool

    public static let unavailable = Self(
        shuffle: false,
        repeatEnabled: false,
        favorite: false,
        shuffleAvailable: false,
        repeatAvailable: false,
        favoriteAvailable: false
    )
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
    public static func seek(to seconds: Double, sourceBundleIdentifier: String? = nil) {
        let clampedSeconds = max(0, seconds)
        // MediaRemote command 24 is SeekToPlaybackPosition.
        let userInfo: NSDictionary = ["kMRMediaRemoteOptionPlaybackPosition": NSNumber(value: clampedSeconds)]
        _ = sendCommand?(24, userInfo)

        let script: String?
        switch scriptablePlayer(for: sourceBundleIdentifier) {
        case .music:
            script = "tell application \"Music\" to set player position to \(clampedSeconds)"
        case .spotify:
            script = "tell application \"Spotify\" to set player position to \(clampedSeconds)"
        case nil:
            script = nil
        }
        guard let script else { return }

        DispatchQueue.global(qos: .userInitiated).async {
            if let appleScript = NSAppleScript(source: script) {
                var errorInfo: NSDictionary?
                appleScript.executeAndReturnError(&errorInfo)
            }
        }
    }

    /// Skips forward or backward by the specified number of seconds.
    public static func skip(seconds: Double, relativeTo current: Double, duration: Double) {
        seek(to: clampedSeekTarget(seconds: seconds, relativeTo: current, duration: duration))
    }

    static func clampedSeekTarget(seconds: Double, relativeTo current: Double, duration: Double) -> Double {
        max(0, min(current + seconds, duration > 0 ? duration : .greatestFiniteMagnitude))
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

    /// Reads the controls that the active scriptable music app actually supports.
    public static func playbackOptions(
        for sourceBundleIdentifier: String?,
        completion: @escaping (SystemMediaPlaybackOptions) -> Void
    ) {
        let source: String
        switch scriptablePlayer(for: sourceBundleIdentifier) {
        case .music:
            source = #"""
            tell application "Music"
                set shuffleState to shuffle enabled
                set repeatState to song repeat is not off
                set favoriteState to false
                set favoriteAvailable to false
                try
                    set favoriteState to favorited of current track
                    set favoriteAvailable to true
                end try
                return {shuffleState, repeatState, favoriteState, true, true, favoriteAvailable}
            end tell
            """#
        case .spotify:
            source = #"""
            tell application "Spotify"
                return {shuffling, repeating, false, true, true, false}
            end tell
            """#
        case nil:
            completion(.unavailable)
            return
        }

        runScript(source) { descriptor in
            guard let descriptor, descriptor.numberOfItems == 6 else {
                completion(.unavailable)
                return
            }
            completion(Self.options(from: descriptor))
        }
    }

    /// Toggles a playback option and returns its new state, or nil when unsupported/failed.
    public static func toggle(
        _ option: SystemMediaOption,
        for sourceBundleIdentifier: String?,
        completion: @escaping (Bool?) -> Void
    ) {
        let script: String?
        switch (scriptablePlayer(for: sourceBundleIdentifier), option) {
        case (.music, .shuffle):
            script = #"""
                tell application "Music" to set shuffle enabled to not shuffle enabled
                tell application "Music" to return shuffle enabled
            """#
        case (.spotify, .shuffle):
            script = #"""
                tell application "Spotify" to set shuffling to not shuffling
                tell application "Spotify" to return shuffling
            """#
        case (.music, .repeatMode):
            script = #"""
                tell application "Music"
                    if song repeat is off then
                        set song repeat to all
                    else
                        set song repeat to off
                    end if
                    return song repeat is not off
                end tell
            """#
        case (.spotify, .repeatMode):
            script = #"""
                tell application "Spotify" to set repeating to not repeating
                tell application "Spotify" to return repeating
            """#
        case (.music, .favorite):
            script = #"""
                tell application "Music"
                    set favorited of current track to not (favorited of current track)
                    return favorited of current track
                end tell
            """#
        case (.spotify, .favorite), (nil, _):
            script = nil
        }

        guard let script else {
            completion(nil)
            return
        }

        runScript(script) { descriptor in
            guard let descriptor, descriptor.descriptorType != typeNull else {
                completion(nil)
                return
            }
            completion(descriptor.booleanValue)
        }
    }

    private static func runScript(_ source: String, completion: @escaping (NSAppleEventDescriptor?) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            var error: NSDictionary?
            let result = NSAppleScript(source: source)?.executeAndReturnError(&error)
            DispatchQueue.main.async { completion(error == nil ? result : nil) }
        }
    }

    enum ScriptablePlayer: Equatable {
        case music
        case spotify
    }

    static func scriptablePlayer(for bundleIdentifier: String?) -> ScriptablePlayer? {
        switch bundleIdentifier {
        case "com.apple.Music": return .music
        case "com.spotify.client": return .spotify
        default: return nil
        }
    }

    private static func options(from descriptor: NSAppleEventDescriptor) -> SystemMediaPlaybackOptions {
        func bool(_ index: Int) -> Bool { descriptor.atIndex(index)?.booleanValue ?? false }
        return .init(
            shuffle: bool(1),
            repeatEnabled: bool(2),
            favorite: bool(3),
            shuffleAvailable: bool(4),
            repeatAvailable: bool(5),
            favoriteAvailable: bool(6)
        )
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
