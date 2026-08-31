import Foundation
import AppKit
import CoreGraphics
import ScreenCaptureKit
import Combine

/// Service managing live visual mirroring of an application window into the ClipNotch Video Capsule.
public final class VideoCapsuleStreamService: NSObject, ObservableObject, @unchecked Sendable {
    public static let shared = VideoCapsuleStreamService()

    @Published public var currentFrame: CGImage?
    @Published public var isStreaming: Bool = false
    @Published public var activeModel: VideoCapsuleModel?
    @Published public var streamError: String?

    private var streamTimer: Timer?
    private var contentFilter: SCContentFilter?
    private var captureConfiguration: SCStreamConfiguration?
    private var captureSessionID = UUID()
    private var isCaptureInFlight = false
    private var consecutiveCaptureFailures = 0
    private var sourceFrameSize: CGSize?

    public override init() {
        super.init()
    }

    /// Starts mirroring a selected window into ClipNotch.
    public func startMirroring(window: WindowInfo, cropRect: CGRect? = nil, scalingMode: VideoScalingMode = .fit, fps: Int = 30) {
        stopMirroring()

        let model = VideoCapsuleModel(
            windowID: window.id,
            appName: window.ownerName,
            windowTitle: window.windowName,
            cropRect: cropRect,
            scalingMode: scalingMode,
            targetFPS: fps
        )

        self.activeModel = model
        self.isStreaming = true
        self.streamError = nil
        let sessionID = UUID()
        self.captureSessionID = sessionID

        AppLogger.shared.info("Starting Video Capsule stream for window: \(window.displayName) @ \(fps) FPS")

        if !CGPreflightScreenCaptureAccess(), !CGRequestScreenCaptureAccess() {
            handleStartFailure("Allow Screen Recording for ClipShot in System Settings, then reopen the app")
            return
        }

        Task { [weak self] in
            do {
                let content = try await SCShareableContent.excludingDesktopWindows(true, onScreenWindowsOnly: true)
                guard let sourceWindow = content.windows.first(where: { $0.windowID == window.id }) else {
                    throw VideoCapsuleError.windowUnavailable
                }

                let filter = SCContentFilter(desktopIndependentWindow: sourceWindow)
                let configuration = SCStreamConfiguration()
                configuration.width = max(1, Int(sourceWindow.frame.width.rounded()))
                configuration.height = max(1, Int(sourceWindow.frame.height.rounded()))
                configuration.showsCursor = false
                configuration.capturesAudio = false

                await MainActor.run { [weak self] in
                    guard let self, self.captureSessionID == sessionID, self.isStreaming else { return }
                    self.contentFilter = filter
                    self.captureConfiguration = configuration
                    self.captureFrame()

                    let interval = 1.0 / Double(max(fps, 10))
                    self.streamTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
                        self?.captureFrame()
                    }
                }
            } catch {
                await MainActor.run { [weak self] in
                    guard let self, self.captureSessionID == sessionID else { return }
                    self.handleStartFailure(error.localizedDescription)
                }
            }
        }
    }

    public func updateScalingMode(_ scalingMode: VideoScalingMode) {
        guard var model = activeModel else { return }
        model.scalingMode = scalingMode
        activeModel = model
        Task { @MainActor in
            ClipNotchViewModel.shared.updateVideo(model: model)
        }
    }

    public func switchSource(to window: WindowInfo) {
        let scalingMode = activeModel?.scalingMode ?? .fit
        let fps = activeModel?.targetFPS ?? AppSettings.shared.clipNotchVideoFPS
        startMirroring(window: window, scalingMode: scalingMode, fps: fps)
        if let model = activeModel {
            Task { @MainActor in
                ClipNotchViewModel.shared.showVideo(model: model)
            }
        }
    }

    /// Updates the crop rect for the currently active stream.
    public func updateCropRect(_ cropRect: CGRect?) {
        guard var model = activeModel else { return }
        model.cropRect = cropRect
        self.activeModel = model
        Task { @MainActor in
            ClipNotchViewModel.shared.updateVideo(model: model)
        }
    }

    public func cropToAspectRatio(_ aspectRatio: CGFloat?) {
        guard let aspectRatio, let sourceFrameSize else {
            updateCropRect(nil)
            return
        }

        let width = sourceFrameSize.width
        let height = sourceFrameSize.height
        let currentRatio = width / height
        let crop: CGRect
        if currentRatio > aspectRatio {
            let cropWidth = height * aspectRatio
            crop = CGRect(x: (width - cropWidth) / 2, y: 0, width: cropWidth, height: height)
        } else {
            let cropHeight = width / aspectRatio
            crop = CGRect(x: 0, y: (height - cropHeight) / 2, width: width, height: cropHeight)
        }
        updateCropRect(crop.integral)
    }

    /// Stops the active stream and releases capture resources.
    public func stopMirroring() {
        streamTimer?.invalidate()
        streamTimer = nil
        captureSessionID = UUID()
        contentFilter = nil
        captureConfiguration = nil
        isCaptureInFlight = false
        consecutiveCaptureFailures = 0

        isStreaming = false
        activeModel = nil
        currentFrame = nil
        streamError = nil
        sourceFrameSize = nil

        AppLogger.shared.info("Stopped Video Capsule stream")
    }

    // MARK: - Frame Capture

    private func captureFrame() {
        guard isStreaming,
              !isCaptureInFlight,
              let model = activeModel,
              let contentFilter,
              let captureConfiguration else { return }

        isCaptureInFlight = true
        let sessionID = captureSessionID
        SCScreenshotManager.captureImage(contentFilter: contentFilter, configuration: captureConfiguration) { [weak self] image, error in
            DispatchQueue.main.async {
                guard let self, self.captureSessionID == sessionID, self.isStreaming else { return }
                self.isCaptureInFlight = false

                guard let image else {
                    self.consecutiveCaptureFailures += 1
                    if self.consecutiveCaptureFailures >= 5 {
                        self.handleSourceClosed(error: error)
                    }
                    return
                }

                self.consecutiveCaptureFailures = 0
                self.sourceFrameSize = CGSize(width: image.width, height: image.height)

                var outputImage = image
                if let crop = model.cropRect,
                   crop.width > 10,
                   crop.height > 10,
                   let cropped = image.cropping(to: crop) {
                    outputImage = cropped
                }
                self.currentFrame = outputImage
            }
        }
    }

    private func handleStartFailure(_ message: String) {
        AppLogger.shared.error("Video Capsule could not start: \(message)")
        stopMirroring()
        streamError = message
        Task { @MainActor in
            ClipNotchViewModel.shared.showError(message)
        }
    }

    private func handleSourceClosed(error: Error?) {
        let message = error?.localizedDescription ?? "Video source ended"
        AppLogger.shared.info("Video Capsule source ended: \(message)")
        stopMirroring()
        streamError = message
        Task { @MainActor in
            ClipNotchViewModel.shared.showError(message)
        }
    }
}

private enum VideoCapsuleError: LocalizedError {
    case windowUnavailable

    var errorDescription: String? {
        "The selected video window is no longer available"
    }
}
