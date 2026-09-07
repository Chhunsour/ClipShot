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
    let currentPlaybackDate: Double?
    let sourcePID: Int32?
}

/// Reads system Now Playing metadata used by macOS media controls with live position tracking and seeking.
public final class SystemNowPlayingService: ObservableObject, @unchecked Sendable {
    public static let shared = SystemNowPlayingService()

    @Published public private(set) var title = ""
    @Published public private(set) var artist = ""
    @Published public private(set) var album = ""
    @Published public private(set) var artwork: NSImage?
    @Published public private(set) var artworkPalette = ArtworkPalette.fallback
    @Published public private(set) var isPlaying = false
    @Published public private(set) var duration: Double = 0
    @Published public private(set) var elapsedTime: Double = 0
    @Published public private(set) var currentPosition: Double = 0
    @Published public private(set) var sourceBundleIdentifier = ""
    @Published public private(set) var sourceAppName = ""

    public var hasMedia: Bool { !title.isEmpty || !artist.isEmpty || artwork != nil }
    public var displayTitle: String {
        [title, artist].filter { !$0.isEmpty }.joined(separator: " — ")
    }
    public var effectiveDuration: Double {
        max(0, duration)
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
        let clamped = duration > 0 ? max(0, min(seconds, duration)) : max(0, seconds)
        basePosition = clamped
        lastSyncTime = Date()
        currentPosition = clamped
        elapsedTime = clamped
        SystemMediaController.seek(to: clamped, sourceBundleIdentifier: sourceBundleIdentifier)
    }

    public func skip(seconds: Double) {
        let target = currentPosition + seconds
        seek(to: target)
    }

    private func tickPosition() {
        guard isPlaying else { return }
        let delta = Date().timeIntervalSince(lastSyncTime)
        let newPos = basePosition + delta
        if duration > 0 && newPos >= duration {
            currentPosition = duration
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

        duration = max(0, snapshot?.duration ?? 0)
        let playbackDate = snapshot?.currentPlaybackDate.flatMap {
            $0 > 0 ? Date(timeIntervalSince1970: $0) : nil
        }
        let resolvedElapsed = Self.resolvedElapsed(
            rawElapsed: snapshot?.elapsedTime,
            playbackDate: playbackDate,
            now: Date(),
            isPlaying: isPlaying,
            duration: duration
        )
        if let el = resolvedElapsed {
            elapsedTime = el
            basePosition = el
            lastSyncTime = Date()
            currentPosition = el
        } else if !wasPlaying && isPlaying {
            lastSyncTime = Date()
        }

        if let pid = snapshot?.sourcePID,
           let app = NSRunningApplication(processIdentifier: pid_t(pid)) {
            sourceBundleIdentifier = app.bundleIdentifier ?? ""
            sourceAppName = app.localizedName ?? ""
        } else {
            sourceBundleIdentifier = ""
            sourceAppName = ""
        }

        let artworkBase64 = snapshot?.artworkBase64 ?? ""
        guard artworkBase64 != currentArtworkBase64 else { return }
        currentArtworkBase64 = artworkBase64
        artwork = Data(base64Encoded: artworkBase64).flatMap(NSImage.init(data:))
        artworkPalette = artwork.map(ArtworkPalette.colors(from:)) ?? ArtworkPalette.fallback
    }

    static func resolvedElapsed(
        rawElapsed: Double?,
        playbackDate: Date?,
        now: Date,
        isPlaying: Bool,
        duration: Double
    ) -> Double? {
        let raw = rawElapsed.flatMap { $0.isFinite && $0 >= 0 ? $0 : nil }
        var elapsed = raw
        if isPlaying, let raw, let playbackDate {
            let delta = now.timeIntervalSince(playbackDate)
            if delta >= 0 { elapsed = raw + delta }
        }
        guard let elapsed else { return nil }
        return duration > 0 ? min(elapsed, duration) : elapsed
    }

    private static let probeSource = #"""
    import Darwin
    import Foundation

    let handle = dlopen("/System/Library/PrivateFrameworks/MediaRemote.framework/MediaRemote", RTLD_NOW)!
    var sourcePID: Int32 = 0
    if let pidSymbol = dlsym(handle, "MRMediaRemoteGetNowPlayingApplicationPID") {
        typealias GetPID = @convention(c) (DispatchQueue, @escaping @convention(block) (Int32) -> Void) -> Void
        let getPID = unsafeBitCast(pidSymbol, to: GetPID.self)
        let pidSemaphore = DispatchSemaphore(value: 0)
        getPID(.global(qos: .utility)) { pid in
            sourcePID = pid
            pidSemaphore.signal()
        }
        _ = pidSemaphore.wait(timeout: .now() + 1)
    }
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
            "elapsedTime": elapsed,
            "currentPlaybackDate": (info?["kMRMediaRemoteNowPlayingInfoTimestamp"] as? Date)?.timeIntervalSince1970 ?? 0,
            "sourcePID": sourcePID
        ]
        if let data = try? JSONSerialization.data(withJSONObject: payload) {
            FileHandle.standardOutput.write(data)
        }
        semaphore.signal()
    }
    _ = semaphore.wait(timeout: .now() + 3)
    """#
}
