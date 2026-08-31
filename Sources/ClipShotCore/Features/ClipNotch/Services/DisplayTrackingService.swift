import Foundation
import AppKit
import CoreGraphics
import Combine

/// Service that discovers, tracks, and monitors physical and virtual displays.
@MainActor
public final class DisplayTrackingService: ObservableObject {
    public static let shared = DisplayTrackingService()

    @Published public var availableDisplays: [DisplayIdentifier] = []
    @Published public var activeTargetDisplay: DisplayIdentifier?

    private var cancellables = Set<AnyCancellable>()

    public init() {
        refreshDisplays()
        setupScreenChangeObserver()

        // React to user's display UUID preference change
        AppSettings.shared.$clipNotchDisplayUUID
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateActiveTargetDisplay()
            }
            .store(in: &cancellables)
    }

    /// Scans connected screens and builds stable DisplayIdentifier models.
    public func refreshDisplays() {
        var displays: [DisplayIdentifier] = []
        let screens = NSScreen.screens

        for screen in screens {
            let directDisplayID = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? CGDirectDisplayID ?? CGMainDisplayID()

            // Get stable display UUID from CoreGraphics
            var uuidString = "display_\(directDisplayID)"
            if let cfUUID = CGDisplayCreateUUIDFromDisplayID(directDisplayID) {
                uuidString = CFUUIDCreateString(kCFAllocatorDefault, cfUUID.takeRetainedValue()) as String
            }

            let isMain = screen == NSScreen.main
            let name = screen.localizedName

            let display = DisplayIdentifier(
                id: uuidString,
                name: name,
                directDisplayID: directDisplayID,
                frame: screen.frame,
                visibleFrame: screen.visibleFrame,
                scaleFactor: screen.backingScaleFactor,
                isMain: isMain
            )
            displays.append(display)
        }

        self.availableDisplays = displays
        updateActiveTargetDisplay()

        AppLogger.shared.info("DisplayTrackingService discovered \(displays.count) screen(s)")
    }

    /// Resolves which display ClipNotch should currently attach to.
    public func updateActiveTargetDisplay() {
        guard !availableDisplays.isEmpty else {
            activeTargetDisplay = nil
            return
        }

        let preferredUUID = AppSettings.shared.clipNotchDisplayUUID

        if let uuid = preferredUUID, let matched = availableDisplays.first(where: { $0.id == uuid }) {
            self.activeTargetDisplay = matched
            return
        }

        // If preferred is disconnected or not set, check fallback
        if AppSettings.shared.clipNotchFallbackToMain || preferredUUID == nil {
            self.activeTargetDisplay = availableDisplays.first(where: { $0.isMain }) ?? availableDisplays.first
        } else {
            self.activeTargetDisplay = nil
        }
    }

    /// Finds the target NSScreen matching the active DisplayIdentifier.
    public func activeNSScreen() -> NSScreen? {
        guard let target = activeTargetDisplay else { return NSScreen.main }
        return NSScreen.screens.first { screen in
            let id = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? CGDirectDisplayID
            return id == target.directDisplayID
        } ?? NSScreen.main
    }

    /// Computes the top-center frame origin for ClipNotch on the active display.
    public func computeNotchOrigin(for size: CGSize, settings: AppSettings = .shared) -> CGPoint {
        guard let screen = activeNSScreen() else {
            return CGPoint(x: 100, y: 100)
        }

        let screenFrame = screen.frame
        let visibleFrame = screen.visibleFrame

        // Top-center X coordinate (exact mathematical center)
        let originX = screenFrame.midX - (size.width / 2.0)

        // Top-center Y coordinate
        var originY: CGFloat
        switch settings.clipNotchPlacementMode {
        case .topHeader:
            // Flush at absolute top edge of physical display (frame.maxY)
            originY = screenFrame.maxY - size.height - CGFloat(settings.clipNotchVerticalOffset)
        case .belowMenuBar:
            // Below the menu bar (visibleFrame.maxY)
            originY = visibleFrame.maxY - size.height - CGFloat(settings.clipNotchVerticalOffset)
        case .floatingIsland:
            // 6pt gap from the top edge
            originY = screenFrame.maxY - size.height - 6.0 - CGFloat(settings.clipNotchVerticalOffset)
        }

        return CGPoint(x: originX, y: originY)
    }

    private func setupScreenChangeObserver() {
        NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            AppLogger.shared.info("Display configuration changed (hotplug/resolution change)")
            Task { @MainActor [weak self] in
                self?.refreshDisplays()
            }
        }
    }
}
