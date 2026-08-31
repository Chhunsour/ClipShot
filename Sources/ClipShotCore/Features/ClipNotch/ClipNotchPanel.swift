import Foundation
import AppKit
import SwiftUI
import Combine

/// Borderless non-activating NSPanel housing ClipNotch.
public final class ClipNotchPanel: NSPanel {
    public override var canBecomeKey: Bool { false }
    public override var canBecomeMain: Bool { false }

    public init() {
        super.init(
            contentRect: NSRect(x: 100, y: 100, width: 100, height: 32),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        self.level = .statusBar
        self.isOpaque = false
        self.backgroundColor = .clear
        self.hasShadow = false // Shadow rendered directly in SwiftUI
        self.isMovableByWindowBackground = false
        self.hidesOnDeactivate = false
        self.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]

        let hostingView = NSHostingView(rootView: ClipNotchView())
        hostingView.sizingOptions = []
        self.contentView = hostingView
    }
}

/// Controller managing ClipNotch panel lifecycle, geometry, and display synchronization.
@MainActor
public final class ClipNotchController {
    public static let shared = ClipNotchController()

    private var panel: ClipNotchPanel?
    private var frameAnimationTimer: Timer?
    private var cancellables = Set<AnyCancellable>()

    public init() {
        setupObservers()
    }

    public func setup() {
        guard panel == nil else { return }

        let p = ClipNotchPanel()
        self.panel = p

        updatePosition()
        updateVisibility()

        AppLogger.shared.info("ClipNotchController initialized")
    }

    public func updateVisibility() {
        guard let p = panel else { return }
        let settings = AppSettings.shared
        let isEnabled = settings.clipNotchEnabled && DisplayTrackingService.shared.activeTargetDisplay != nil

        var behavior: NSWindow.CollectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]
        if settings.clipNotchShowInFullscreen {
            behavior.insert(.fullScreenAuxiliary)
        }
        p.collectionBehavior = behavior

        if isEnabled {
            p.orderFrontRegardless()
        } else {
            p.orderOut(nil)
        }
    }

    public func containsMouse() -> Bool {
        panel?.frame.insetBy(dx: -2, dy: -2).contains(NSEvent.mouseLocation) == true
    }

    public func updatePosition() {
        guard let p = panel, AppSettings.shared.clipNotchEnabled else { return }

        let state = ClipNotchViewModel.shared.currentState
        let targetSize = sizeForState(state)
        let origin = DisplayTrackingService.shared.computeNotchOrigin(for: targetSize)

        let newFrame = CGRect(origin: origin, size: targetSize)

        if NSWorkspace.shared.accessibilityDisplayShouldReduceMotion || !p.isVisible {
            frameAnimationTimer?.invalidate()
            p.setFrame(newFrame, display: false)
        } else {
            animateFrame(of: p, to: newFrame)
        }
    }

    private func animateFrame(of panel: NSPanel, to targetFrame: CGRect) {
        frameAnimationTimer?.invalidate()
        let startFrame = panel.frame
        let startedAt = ProcessInfo.processInfo.systemUptime
        let duration = 0.42

        let timer = Timer(timeInterval: 1.0 / 60.0, repeats: true) { [weak panel] timer in
            guard let panel else {
                timer.invalidate()
                return
            }

            let progress = min(1, (ProcessInfo.processInfo.systemUptime - startedAt) / duration)
            let eased = CGFloat(progress * progress * (3 - 2 * progress))
            let frame = CGRect(
                x: startFrame.origin.x + (targetFrame.origin.x - startFrame.origin.x) * eased,
                y: startFrame.origin.y + (targetFrame.origin.y - startFrame.origin.y) * eased,
                width: startFrame.width + (targetFrame.width - startFrame.width) * eased,
                height: startFrame.height + (targetFrame.height - startFrame.height) * eased
            )
            // Redrawing synchronously while SwiftUI is laying out the hosting view
            // can recurse back into AppKit layout during rapid notch transitions.
            panel.setFrame(frame, display: false)

            if progress >= 1 {
                timer.invalidate()
            }
        }
        frameAnimationTimer = timer
        RunLoop.main.add(timer, forMode: .common)
    }

    private func sizeForState(_ state: ClipNotchState) -> CGSize {
        switch state {
        case .idle:
            return AppSettings.shared.clipNotchSize.idleDimensions

        case .quickActions:
            return CGSize(width: 300, height: 38)

        case .screenshotPreview, .videoInterruptedByScreenshot:
            return CGSize(width: 138, height: 34)

        case .video:
            let dims = AppSettings.shared.clipNotchVideoSize.dimensions
            return CGSize(width: dims.width, height: dims.height)

        case .recording:
            return CGSize(width: 180, height: 34)

        case .ocrResult:
            return CGSize(width: 240, height: 34)

        case .colorResult:
            return CGSize(width: 200, height: 34)

        case .error:
            return CGSize(width: 260, height: 38)

        case .fileDropHover:
            return CGSize(width: 160, height: 54)

        case .recentShelf:
            return CGSize(width: 410, height: 168)
        }
    }

    private func setupObservers() {
        // React to settings changes
        AppSettings.shared.$clipNotchEnabled
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateVisibility()
                self?.updatePosition()
            }
            .store(in: &cancellables)

        AppSettings.shared.$clipNotchPlacementMode
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updatePosition()
            }
            .store(in: &cancellables)

        AppSettings.shared.$clipNotchVerticalOffset
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updatePosition()
            }
            .store(in: &cancellables)

        AppSettings.shared.$clipNotchSize
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updatePosition()
            }
            .store(in: &cancellables)

        AppSettings.shared.$clipNotchVideoSize
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updatePosition()
            }
            .store(in: &cancellables)

        AppSettings.shared.$clipNotchShowInFullscreen
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateVisibility()
            }
            .store(in: &cancellables)

        AppSettings.shared.$clipNotchFallbackToMain
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateVisibility()
                self?.updatePosition()
            }
            .store(in: &cancellables)

        // React to state changes to resize the notch dynamically
        ClipNotchViewModel.shared.$currentState
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateVisibility()
                self?.updatePosition()
            }
            .store(in: &cancellables)

        // React to display hotplugging
        DisplayTrackingService.shared.$activeTargetDisplay
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updatePosition()
            }
            .store(in: &cancellables)
    }
}
