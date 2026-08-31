import Foundation
import AppKit
import AVFoundation
import CoreGraphics

/// Screen recording engine supporting Area, Window, and Full Screen capture to MP4/MOV and animated GIF.
public final class ScreenRecordingEngine: NSObject, ObservableObject, @unchecked Sendable {
    public static let shared = ScreenRecordingEngine()

    @Published public var isRecording: Bool = false
    @Published public var isPaused: Bool = false
    @Published public var durationSeconds: Int = 0

    private var timer: Timer?
    private var assetWriter: AVAssetWriter?
    private var writerInput: AVAssetWriterInput?
    private var adaptor: AVAssetWriterInputPixelBufferAdaptor?

    private var targetRect: CGRect = .zero
    private var outputURL: URL?
    private var frameCount: Int64 = 0
    private var captureTimer: Timer?
    private var isGIF: Bool = false
    private var gifFrames: [CGImage] = []

    private var indicatorWindow: NSWindow?

    public override init() {
        super.init()
    }

    /// Starts recording the specified region.
    public func startRecording(rect: CGRect, asGIF: Bool = false) {
        stopRecording(save: false)

        self.targetRect = rect
        self.isGIF = asGIF
        self.isRecording = true
        self.isPaused = false
        self.durationSeconds = 0
        self.frameCount = 0
        self.gifFrames = []

        let destinationFolder = PathUtils.shared.activeScreenshotFolder()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd 'at' HH.mm.ss"
        let timestamp = formatter.string(from: Date())
        let ext = asGIF ? "gif" : "mp4"
        self.outputURL = destinationFolder.appendingPathComponent("Screen Recording \(timestamp).\(ext)")

        if asGIF {
            startGIFCapture()
        } else {
            setupAssetWriter(rect: rect)
        }

        startTimer()
        showRecordingIndicator()

        DispatchQueue.main.async {
            ClipNotchViewModel.shared.showRecording(duration: 0, isPaused: false)
        }

        AppLogger.shared.info("Started screen recording: \(outputURL?.lastPathComponent ?? "")")
    }

    public func pauseRecording() {
        guard isRecording, !isPaused else { return }
        isPaused = true
        DispatchQueue.main.async {
            ClipNotchViewModel.shared.showRecording(duration: self.durationSeconds, isPaused: true)
        }
        AppLogger.shared.info("Paused screen recording")
    }

    public func resumeRecording() {
        guard isRecording, isPaused else { return }
        isPaused = false
        DispatchQueue.main.async {
            ClipNotchViewModel.shared.showRecording(duration: self.durationSeconds, isPaused: false)
        }
        AppLogger.shared.info("Resumed screen recording")
    }

    public func stopRecording(save: Bool = true) {
        guard isRecording else { return }

        timer?.invalidate()
        timer = nil
        captureTimer?.invalidate()
        captureTimer = nil

        hideRecordingIndicator()
        isRecording = false
        isPaused = false

        DispatchQueue.main.async {
            ClipNotchViewModel.shared.showIdle()
        }

        guard save, let output = outputURL else {
            if let output = outputURL { try? FileManager.default.removeItem(at: output) }
            return
        }

        if isGIF {
            saveGIF(to: output)
        } else {
            finishAssetWriter(to: output)
        }
    }

    // MARK: - Video Setup

    private func setupAssetWriter(rect: CGRect) {
        guard let output = outputURL else { return }
        try? FileManager.default.removeItem(at: output)

        do {
            let writer = try AVAssetWriter(outputURL: output, fileType: .mp4)

            let width = Int(rect.width) % 2 == 0 ? Int(rect.width) : Int(rect.width) + 1
            let height = Int(rect.height) % 2 == 0 ? Int(rect.height) : Int(rect.height) + 1

            let videoSettings: [String: Any] = [
                AVVideoCodecKey: AVVideoCodecType.h264,
                AVVideoWidthKey: width,
                AVVideoHeightKey: height,
                AVVideoCompressionPropertiesKey: [
                    AVVideoAverageBitRateKey: 6_000_000,
                    AVVideoProfileLevelKey: AVVideoProfileLevelH264HighAutoLevel
                ]
            ]

            let input = AVAssetWriterInput(mediaType: .video, outputSettings: videoSettings)
            input.expectsMediaDataInRealTime = true

            let bufferAttributes: [String: Any] = [
                kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32ARGB),
                kCVPixelBufferWidthKey as String: width,
                kCVPixelBufferHeightKey as String: height
            ]

            let pixelAdaptor = AVAssetWriterInputPixelBufferAdaptor(
                assetWriterInput: input,
                sourcePixelBufferAttributes: bufferAttributes
            )

            if writer.canAdd(input) {
                writer.add(input)
            }

            writer.startWriting()
            writer.startSession(atSourceTime: .zero)

            self.assetWriter = writer
            self.writerInput = input
            self.adaptor = pixelAdaptor

            // Frame capture timer at 30 FPS
            captureTimer = Timer.scheduledTimer(withTimeInterval: 1.0 / 30.0, repeats: true) { [weak self] _ in
                self?.captureVideoFrame()
            }
        } catch {
            AppLogger.shared.error("Failed to setup AVAssetWriter: \(error.localizedDescription)")
        }
    }

    private func captureVideoFrame() {
        guard isRecording, !isPaused, let writer = assetWriter, writer.status == .writing,
              let input = writerInput, input.isReadyForMoreMediaData,
              let adaptor = adaptor else {
            return
        }

        guard let img = ScreenCaptureEngine.shared.captureRect(targetRect),
              let cgImage = img.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            return
        }

        if let buffer = createPixelBuffer(from: cgImage) {
            let presentationTime = CMTime(value: frameCount, timescale: 30)
            adaptor.append(buffer, withPresentationTime: presentationTime)
            frameCount += 1
        }
    }

    private func finishAssetWriter(to output: URL) {
        writerInput?.markAsFinished()
        assetWriter?.finishWriting { [weak self] in
            AppLogger.shared.info("Finished recording video to: \(output.path)")
            DispatchQueue.main.async {
                SoundManager.shared.playCopySound()
            }
        }
    }

    // MARK: - GIF Capture

    private func startGIFCapture() {
        captureTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self, self.isRecording, !self.isPaused else { return }
            if let img = ScreenCaptureEngine.shared.captureRect(self.targetRect),
               let cgImage = img.cgImage(forProposedRect: nil, context: nil, hints: nil) {
                self.gifFrames.append(cgImage)
            }
        }
    }

    private func saveGIF(to output: URL) {
        guard !gifFrames.isEmpty else { return }

        guard let destination = CGImageDestinationCreateWithURL(
            output as CFURL,
            kUTTypeGIF as! CFString,
            gifFrames.count,
            nil
        ) else { return }

        let fileProperties: [String: Any] = [
            kCGImagePropertyGIFDictionary as String: [
                kCGImagePropertyGIFLoopCount as String: 0
            ]
        ]
        CGImageDestinationSetProperties(destination, fileProperties as CFDictionary)

        let frameProperties: [String: Any] = [
            kCGImagePropertyGIFDictionary as String: [
                kCGImagePropertyGIFDelayTime as String: 0.1
            ]
        ]

        for frame in gifFrames {
            CGImageDestinationAddImage(destination, frame, frameProperties as CFDictionary)
        }

        CGImageDestinationFinalize(destination)
        AppLogger.shared.info("Saved GIF recording to: \(output.path)")
        SoundManager.shared.playCopySound()
    }

    // MARK: - Timer & Indicator

    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self, !self.isPaused else { return }
            self.durationSeconds += 1
        }
    }

    private func showRecordingIndicator() {
        DispatchQueue.main.async {
            if self.indicatorWindow == nil {
                let win = NSWindow(
                    contentRect: NSRect(x: 100, y: 100, width: 140, height: 36),
                    styleMask: [.borderless, .nonactivatingPanel],
                    backing: .buffered,
                    defer: false
                )
                win.level = .floating
                win.backgroundColor = .clear
                win.isOpaque = false
                win.hasShadow = true
                self.indicatorWindow = win
            }

            guard let screen = NSScreen.main else { return }
            let origin = CGPoint(x: screen.visibleFrame.midX - 70, y: screen.visibleFrame.maxY - 50)
            self.indicatorWindow?.setFrameOrigin(origin)
            self.indicatorWindow?.orderFront(nil)
        }
    }

    private func hideRecordingIndicator() {
        DispatchQueue.main.async {
            self.indicatorWindow?.orderOut(nil)
            self.indicatorWindow = nil
        }
    }

    private func createPixelBuffer(from image: CGImage) -> CVPixelBuffer? {
        var pixelBuffer: CVPixelBuffer?
        let width = image.width
        let height = image.height

        let attrs: [String: Any] = [
            kCVPixelBufferCGImageCompatibilityKey as String: true,
            kCVPixelBufferCGBitmapContextCompatibilityKey as String: true
        ]

        let status = CVPixelBufferCreate(
            kCFAllocatorDefault,
            width,
            height,
            kCVPixelFormatType_32ARGB,
            attrs as CFDictionary,
            &pixelBuffer
        )

        guard status == kCVReturnSuccess, let buffer = pixelBuffer else { return nil }

        CVPixelBufferLockBaseAddress(buffer, [])
        let pixelData = CVPixelBufferGetBaseAddress(buffer)

        let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
        let context = CGContext(
            data: pixelData,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: CVPixelBufferGetBytesPerRow(buffer),
            space: rgbColorSpace,
            bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue
        )

        context?.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
        CVPixelBufferUnlockBaseAddress(buffer, [])

        return buffer
    }
}
