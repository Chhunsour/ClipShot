import Foundation
import AppKit
import SwiftUI
import Combine

/// Central state coordinator and view model for ClipNotch.
@MainActor
public final class ClipNotchViewModel: ObservableObject {
    public static let shared = ClipNotchViewModel()

    @Published public var currentState: ClipNotchState = .idle
    @Published public var isHovered: Bool = false
    @Published public var recentItems: [ScreenshotItem] = []
    @Published public var selectedRecentIndex: Int = 0
    @Published public var isExpandedMiniPlayer: Bool = false

    private var dismissTimer: Timer?
    private var activeVideoModel: VideoCapsuleModel?
    private var cancellables = Set<AnyCancellable>()

    public init() {
        refreshRecentItems()
    }

    public func refreshRecentItems() {
        self.recentItems = Array(HistoryManager.shared.items.prefix(5))
    }

    // MARK: - State Transitions

    public func showIdle() {
        cancelDismissTimer()
        if let video = activeVideoModel, VideoCapsuleStreamService.shared.isStreaming {
            self.currentState = .video(model: video)
        } else {
            self.currentState = .idle
        }
    }

    public func showQuickActions() {
        cancelDismissTimer()
        self.currentState = .quickActions
    }

    public func showScreenshot(item: ScreenshotItem, image: NSImage) {
        cancelDismissTimer()
        refreshRecentItems()

        if case .video(let videoModel) = currentState {
            self.activeVideoModel = videoModel
            self.currentState = .videoInterruptedByScreenshot(video: videoModel, screenshot: item, image: image)
        } else if case .videoInterruptedByScreenshot(let videoModel, _, _) = currentState {
            self.activeVideoModel = videoModel
            self.currentState = .videoInterruptedByScreenshot(video: videoModel, screenshot: item, image: image)
        } else if let videoModel = activeVideoModel, VideoCapsuleStreamService.shared.isStreaming {
            self.currentState = .videoInterruptedByScreenshot(video: videoModel, screenshot: item, image: image)
        } else {
            self.currentState = .screenshotPreview(item: item, image: image)
        }

        scheduleAutoCollapse(after: 1.4)
    }

    public func showVideo(model: VideoCapsuleModel) {
        cancelDismissTimer()
        self.activeVideoModel = model
        self.currentState = .video(model: model)
    }

    public func updateVideo(model: VideoCapsuleModel) {
        activeVideoModel = model
        switch currentState {
        case .video:
            currentState = .video(model: model)
        case .videoInterruptedByScreenshot(_, let item, let image):
            currentState = .videoInterruptedByScreenshot(video: model, screenshot: item, image: image)
        default:
            break
        }
    }

    public func stopVideo() {
        self.activeVideoModel = nil
        VideoCapsuleStreamService.shared.stopMirroring()
        showIdle()
    }

    public func showRecording(duration: Int, isPaused: Bool) {
        cancelDismissTimer()
        self.currentState = .recording(durationSeconds: duration, isPaused: isPaused)
    }

    public func showOCRResult(text: String) {
        cancelDismissTimer()
        self.currentState = .ocrResult(text: text)
        scheduleAutoCollapse()
    }

    public func showColorResult(color: NSColor, hex: String) {
        cancelDismissTimer()
        let rgb = ColorPickerService.shared.rgbString(from: color)
        let hsl = ColorPickerService.shared.hslString(from: color)
        self.currentState = .colorResult(hex: hex, rgb: rgb, hsl: hsl)
        scheduleAutoCollapse()
    }

    public func showError(_ message: String) {
        cancelDismissTimer()
        currentState = .error(message: message)
        scheduleAutoCollapse()
    }

    public func showMusicPlayer() {
        cancelDismissTimer()
        self.currentState = .musicPlayer
    }

    public func toggleMusicPlayer() {
        if currentState == .musicPlayer {
            showIdle()
        } else {
            showMusicPlayer()
        }
    }

    public func showRecentShelf() {
        cancelDismissTimer()
        refreshRecentItems()
        self.currentState = .recentShelf(items: recentItems)
    }

    public func setHovered(_ hovered: Bool) {
        self.isHovered = hovered

        if hovered {
            cancelDismissTimer()
            if currentState == .idle,
               AppSettings.shared.clipNotchExpandOnHover,
               AppSettings.shared.clipNotchIdleContent == .empty {
                self.currentState = .quickActions
            }
        } else {
            if currentState == .quickActions {
                showIdle()
            } else if currentState == .musicPlayer {
                scheduleAutoCollapse(after: 0.25)
            } else if case .screenshotPreview = currentState {
                scheduleAutoCollapse(after: 1.4)
            } else if case .videoInterruptedByScreenshot = currentState {
                scheduleAutoCollapse(after: 1.4)
            } else if shouldAutoCollapse(state: currentState) {
                scheduleAutoCollapse()
            }
        }
    }

    // MARK: - Auto Collapse

    private func shouldAutoCollapse(state: ClipNotchState) -> Bool {
        switch state {
        case .screenshotPreview, .videoInterruptedByScreenshot, .ocrResult, .colorResult, .error, .musicPlayer:
            return true
        default:
            return false
        }
    }

    private func scheduleAutoCollapse(after customDuration: Double? = nil) {
        cancelDismissTimer()

        let duration = customDuration ?? AppSettings.shared.clipNotchAutoCollapseDuration
        guard duration > 0 else { return }

        dismissTimer = Timer.scheduledTimer(withTimeInterval: duration, repeats: false) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self = self, !self.isHovered else { return }

                if case .videoInterruptedByScreenshot(let video, _, _) = self.currentState {
                    self.currentState = .video(model: video)
                } else if let video = self.activeVideoModel, VideoCapsuleStreamService.shared.isStreaming {
                    self.currentState = .video(model: video)
                } else {
                    self.showIdle()
                }
            }
        }
    }

    private func cancelDismissTimer() {
        dismissTimer?.invalidate()
        dismissTimer = nil
    }
}
