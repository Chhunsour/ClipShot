import AppKit
import Darwin

public enum SystemMediaCommand: Int32, Sendable {
    case playPause = 16
    case next = 17
    case previous = 18
}

/// Sends the same system media-key events as the keyboard play/skip controls.
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
