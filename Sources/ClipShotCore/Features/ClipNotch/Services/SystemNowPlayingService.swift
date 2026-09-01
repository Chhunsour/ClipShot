import AppKit
import Combine
import Foundation

struct SystemMediaSnapshot: Decodable, Equatable {
    let title: String
    let artist: String
    let album: String?
    let artworkBase64: String
    let isPlaying: Bool
    let duration: Double?
    let elapsedTime: Double?
}

/// Reads system Now Playing metadata used by macOS media controls with live position tracking and seeking.
public final class SystemNowPlayingService: ObservableObject, @unchecked Sendable {
    public static let shared = SystemNowPlayingService()

    @Published public private(set) var title = ""
    @Published public private(set) var artist = ""
    @Published public private(set) var album = ""
    @Published public private(set) var artwork: NSImage?
    @Published public private(set) var isPlaying = false
    @Published public private(set) var duration: Double = 0
    @Published public private(set) var elapsedTime: Double = 0
    @Published public private(set) var currentPosition: Double = 0

    public var hasMedia: Bool { !title.isEmpty || !artist.isEmpty || artwork != nil }
    public var displayTitle: String {
        [title, artist].filter { !$0.isEmpty }.joined(separator: " — ")
    }
    public var effectiveDuration: Double {
        duration > 0 ? duration : 210
    }

    private var timer: Timer?
    private var positionTicker: Timer?
    private var isRefreshInFlight = false
    private var currentArtworkBase64 = ""
    private var lastSyncTime: Date = Date()
    private var basePosition: Double = 0

    public init() {
        DispatchQueue.main.async { [weak self] in
            self?.refresh()
            self?.timer = Timer.scheduledTimer(withTimeInterval: 3.5, repeats: true) { [weak self] _ in
                self?.refresh()
            }
            self?.positionTicker = Timer.scheduledTimer(withTimeInterval: 0.25, repeats: true) { [weak self] _ in
                self?.tickPosition()
            }
        }
    }

    public func refresh() {
        guard !isRefreshInFlight else { return }
        isRefreshInFlight = true

        DispatchQueue.global(qos: .utility).async { [weak self] in
            let snapshot = Self.readSystemNowPlaying()
            DispatchQueue.main.async { self?.apply(snapshot) }
        }
    }

    public func seek(to seconds: Double) {
        let clamped = max(0, min(seconds, effectiveDuration))
        basePosition = clamped
        lastSyncTime = Date()
        currentPosition = clamped
        elapsedTime = clamped
        SystemMediaController.seek(to: clamped)
    }

    public func skip(seconds: Double) {
        let target = currentPosition + seconds
        seek(to: target)
    }

    private func tickPosition() {
        guard isPlaying else { return }
        let delta = Date().timeIntervalSince(lastSyncTime)
        let newPos = basePosition + delta
        if effectiveDuration > 0 && newPos >= effectiveDuration {
            currentPosition = effectiveDuration
        } else {
            currentPosition = newPos
        }
    }

    private static func readSystemNowPlaying() -> SystemMediaSnapshot? {
        let process = Process()
        let input = Pipe()
        let output = Pipe()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/swift")
        process.arguments = ["-"]
        process.standardInput = input
        process.standardOutput = output
        process.standardError = Pipe()

        do {
            try process.run()
            input.fileHandleForWriting.write(Data(probeSource.utf8))
            input.fileHandleForWriting.closeFile()
            process.waitUntilExit()
            guard process.terminationStatus == 0 else { return nil }
            let data = output.fileHandleForReading.readDataToEndOfFile()
            return try JSONDecoder().decode(SystemMediaSnapshot.self, from: data)
        } catch {
            return nil
        }
    }

    private func apply(_ snapshot: SystemMediaSnapshot?) {
        isRefreshInFlight = false
        title = snapshot?.title ?? ""
        artist = snapshot?.artist ?? ""
        album = snapshot?.album ?? ""
        let wasPlaying = isPlaying
        isPlaying = snapshot?.isPlaying ?? false

        if let dur = snapshot?.duration, dur > 0 {
            duration = dur
        }
        if let el = snapshot?.elapsedTime, el >= 0 {
            elapsedTime = el
            basePosition = el
            lastSyncTime = Date()
            currentPosition = el
        } else if !wasPlaying && isPlaying {
            lastSyncTime = Date()
        }

        let artworkBase64 = snapshot?.artworkBase64 ?? ""
        guard artworkBase64 != currentArtworkBase64 else { return }
        currentArtworkBase64 = artworkBase64
        artwork = Data(base64Encoded: artworkBase64).flatMap(NSImage.init(data:))
    }

    private static let probeSource = #"""
    import Darwin
    import Foundation

    let handle = dlopen("/System/Library/PrivateFrameworks/MediaRemote.framework/MediaRemote", RTLD_NOW)!
    typealias GetInfo = @convention(c) (DispatchQueue, @escaping @convention(block) (NSDictionary?) -> Void) -> Void
    let getInfo = unsafeBitCast(dlsym(handle, "MRMediaRemoteGetNowPlayingInfo"), to: GetInfo.self)
    let semaphore = DispatchSemaphore(value: 0)
    getInfo(.global(qos: .utility)) { info in
        let duration = (info?["kMRMediaRemoteNowPlayingInfoDuration"] as? NSNumber)?.doubleValue ?? 0
        let elapsed = (info?["kMRMediaRemoteNowPlayingInfoElapsedTime"] as? NSNumber)?.doubleValue ?? 0
        let payload: [String: Any] = [
            "title": info?["kMRMediaRemoteNowPlayingInfoTitle"] as? String ?? "",
            "artist": info?["kMRMediaRemoteNowPlayingInfoArtist"] as? String ?? "",
            "album": info?["kMRMediaRemoteNowPlayingInfoAlbum"] as? String ?? "",
            "artworkBase64": (info?["kMRMediaRemoteNowPlayingInfoArtworkData"] as? Data)?.base64EncodedString() ?? "",
            "isPlaying": ((info?["kMRMediaRemoteNowPlayingInfoPlaybackRate"] as? NSNumber)?.doubleValue ?? 0) > 0,
            "duration": duration,
            "elapsedTime": elapsed
        ]
        if let data = try? JSONSerialization.data(withJSONObject: payload) {
            FileHandle.standardOutput.write(data)
        }
        semaphore.signal()
    }
    _ = semaphore.wait(timeout: .now() + 3)
    """#
}
