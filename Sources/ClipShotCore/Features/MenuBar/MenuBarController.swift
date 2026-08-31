import Foundation
import AppKit
import Combine

/// Manages the native macOS menu-bar status item, icon states, and dynamic menu actions.
@MainActor
public final class MenuBarController: NSObject, NSMenuDelegate {
    public static let shared = MenuBarController()

    private var statusItem: NSStatusItem?
    private var cancellables = Set<AnyCancellable>()

    public override init() {
        super.init()
    }

    public func setupStatusItem() {
        guard statusItem == nil else { return }

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem?.isVisible = AppSettings.shared.showMenuBarIcon
        updateStatusItemIcon()

        let menu = NSMenu()
        menu.delegate = self
        statusItem?.menu = menu

        rebuildMenu()

        // Observe monitoring active changes
        AppSettings.shared.$monitoringActive
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateStatusItemIcon()
                self?.rebuildMenu()
            }
            .store(in: &cancellables)

        AppSettings.shared.$showMenuBarIcon
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isVisible in
                self?.statusItem?.isVisible = isVisible
            }
            .store(in: &cancellables)
    }

    public func updateStatusItemIcon() {
        guard let button = statusItem?.button else { return }
        let isMonitoring = AppSettings.shared.monitoringActive

        let symbolName = "camera.viewfinder"
        let image = NSImage(systemSymbolName: symbolName, accessibilityDescription: "\(AppConfig.appName) Menu")

        image?.isTemplate = true
        button.image = image
        button.toolTip = "\(AppConfig.appName) — \(isMonitoring ? "Monitoring Active" : "Monitoring Paused")"
        button.alphaValue = isMonitoring ? 1.0 : 0.5
    }

    public func rebuildMenu() {
        guard let menu = statusItem?.menu else { return }
        menu.removeAllItems()

        let isMonitoring = AppSettings.shared.monitoringActive

        // 1. Capture Suite
        let overlayItem = NSMenuItem(title: "New Capture...", action: #selector(openOverlayAction), keyEquivalent: "2")
        overlayItem.keyEquivalentModifierMask = [.command, .shift]
        overlayItem.target = self
        overlayItem.image = NSImage(systemSymbolName: "camera.viewfinder", accessibilityDescription: nil)
        menu.addItem(overlayItem)

        let captureAreaItem = NSMenuItem(title: "Capture Area", action: #selector(captureAreaAction), keyEquivalent: "")
        captureAreaItem.target = self
        captureAreaItem.image = NSImage(systemSymbolName: "crop", accessibilityDescription: nil)
        menu.addItem(captureAreaItem)

        let captureWindowItem = NSMenuItem(title: "Capture Window", action: #selector(captureWindowAction), keyEquivalent: "")
        captureWindowItem.target = self
        captureWindowItem.image = NSImage(systemSymbolName: "rectangle.inset.filled", accessibilityDescription: nil)
        menu.addItem(captureWindowItem)

        let captureScreenItem = NSMenuItem(title: "Capture Full Screen", action: #selector(captureScreenAction), keyEquivalent: "")
        captureScreenItem.target = self
        captureScreenItem.image = NSImage(systemSymbolName: "macwindow", accessibilityDescription: nil)
        menu.addItem(captureScreenItem)

        let scrollingItem = NSMenuItem(title: "Scrolling Capture", action: #selector(scrollingCaptureAction), keyEquivalent: "")
        scrollingItem.target = self
        scrollingItem.image = NSImage(systemSymbolName: "arrow.down.doc", accessibilityDescription: nil)
        menu.addItem(scrollingItem)

        menu.addItem(NSMenuItem.separator())

        // 2. OCR & Recording
        let ocrItem = NSMenuItem(title: "OCR Area", action: #selector(ocrAreaAction), keyEquivalent: "")
        ocrItem.target = self
        ocrItem.image = NSImage(systemSymbolName: "text.viewfinder", accessibilityDescription: nil)
        menu.addItem(ocrItem)

        let recordItem = NSMenuItem(title: "Record Screen", action: #selector(recordScreenAction), keyEquivalent: "")
        recordItem.target = self
        recordItem.image = NSImage(systemSymbolName: "record.circle", accessibilityDescription: nil)
        menu.addItem(recordItem)

        let colorItem = NSMenuItem(title: "Color Picker", action: #selector(colorPickerAction), keyEquivalent: "")
        colorItem.target = self
        colorItem.image = NSImage(systemSymbolName: "eyedropper", accessibilityDescription: nil)
        menu.addItem(colorItem)

        let measureItem = NSMenuItem(title: "Measure Tool", action: #selector(measureAction), keyEquivalent: "")
        measureItem.target = self
        measureItem.image = NSImage(systemSymbolName: "ruler", accessibilityDescription: nil)
        menu.addItem(measureItem)

        menu.addItem(NSMenuItem.separator())

        // 3. Quick Actions
        let copyLastItem = NSMenuItem(title: "Copy Last Capture", action: #selector(copyLastScreenshotAction), keyEquivalent: "")
        copyLastItem.target = self
        copyLastItem.image = NSImage(systemSymbolName: "doc.on.doc", accessibilityDescription: nil)
        copyLastItem.isEnabled = HistoryManager.shared.lastScreenshot != nil
        menu.addItem(copyLastItem)

        let editLastItem = NSMenuItem(title: "Edit Last Capture", action: #selector(editLastCaptureAction), keyEquivalent: "")
        editLastItem.target = self
        editLastItem.image = NSImage(systemSymbolName: "pencil.tip.crop.circle", accessibilityDescription: nil)
        editLastItem.isEnabled = HistoryManager.shared.lastScreenshot?.effectiveImageURL != nil
        menu.addItem(editLastItem)

        let pinLastItem = NSMenuItem(title: "Pin Last Capture", action: #selector(pinLastCaptureAction), keyEquivalent: "")
        pinLastItem.target = self
        pinLastItem.image = NSImage(systemSymbolName: "pin.fill", accessibilityDescription: nil)
        pinLastItem.isEnabled = HistoryManager.shared.lastScreenshot?.effectiveImageURL != nil
        menu.addItem(pinLastItem)

        let historyItem = NSMenuItem(title: "Open History...", action: #selector(openHistoryAction), keyEquivalent: "H")
        historyItem.keyEquivalentModifierMask = [.command, .shift]
        historyItem.target = self
        historyItem.image = NSImage(systemSymbolName: "clock", accessibilityDescription: nil)
        menu.addItem(historyItem)

        let paletteItem = NSMenuItem(title: "Command Palette...", action: #selector(openPaletteAction), keyEquivalent: " ")
        paletteItem.keyEquivalentModifierMask = [.option]
        paletteItem.target = self
        paletteItem.image = NSImage(systemSymbolName: "command", accessibilityDescription: nil)
        menu.addItem(paletteItem)

        menu.addItem(NSMenuItem.separator())

        // 4. Monitoring Toggle & Preferences
        let statusTitle = isMonitoring ? "Pause ClipShot" : "Resume ClipShot"
        let statusMenuItem = NSMenuItem(title: statusTitle, action: #selector(toggleMonitoringAction), keyEquivalent: "")
        statusMenuItem.target = self
        statusMenuItem.image = NSImage(systemSymbolName: isMonitoring ? "pause.circle" : "play.circle", accessibilityDescription: nil)
        menu.addItem(statusMenuItem)

        let settingsItem = NSMenuItem(title: "Settings...", action: #selector(openSettingsAction), keyEquivalent: ",")
        settingsItem.target = self
        settingsItem.image = NSImage(systemSymbolName: "gearshape", accessibilityDescription: nil)
        menu.addItem(settingsItem)

        menu.addItem(NSMenuItem.separator())

        // 5. Quit
        let quitItem = NSMenuItem(title: "Quit \(AppConfig.appName)", action: #selector(quitAction), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)
    }

    // MARK: - Actions

    @objc private func openOverlayAction() {
        CaptureOverlayController.shared.showOverlay(initialMode: .area)
    }

    @objc private func captureAreaAction() {
        CaptureOverlayController.shared.showOverlay(initialMode: .area)
    }

    @objc private func captureWindowAction() {
        CaptureOverlayController.shared.showOverlay(initialMode: .window)
    }

    @objc private func captureScreenAction() {
        CaptureOverlayController.shared.showOverlay(initialMode: .screen)
    }

    @objc private func scrollingCaptureAction() {
        CaptureOverlayController.shared.showOverlay(initialMode: .scrolling)
    }

    @objc private func ocrAreaAction() {
        CaptureOverlayController.shared.showOverlay(initialMode: .ocr)
    }

    @objc private func recordScreenAction() {
        CaptureOverlayController.shared.showOverlay(initialMode: .record)
    }

    @objc private func colorPickerAction() {
        CaptureOverlayController.shared.showOverlay(initialMode: .colorPicker)
    }

    @objc private func measureAction() {
        CaptureOverlayController.shared.showOverlay(initialMode: .measure)
    }

    @objc private func copyLastScreenshotAction() {
        guard let item = HistoryManager.shared.lastScreenshot,
              let url = item.effectiveImageURL,
              let image = ImageUtils.loadImage(at: url) else { return }

        ClipboardManager.shared.copy(image: image, fileURL: url)
        SoundManager.shared.playCopySound()
    }

    @objc private func editLastCaptureAction() {
        guard let item = HistoryManager.shared.lastScreenshot,
              let url = item.effectiveImageURL,
              let image = ImageUtils.loadImage(at: url) else { return }
        MarkupWindowController.open(image: image, sourceURL: url)
    }

    @objc private func pinLastCaptureAction() {
        guard let item = HistoryManager.shared.lastScreenshot,
              let url = item.effectiveImageURL,
              let image = ImageUtils.loadImage(at: url) else { return }
        PinnedImageWindowController.pin(image: image, title: item.fileName)
    }

    @objc private func openHistoryAction() {
        HistoryWindowController.shared.showHistory()
    }

    @objc private func openPaletteAction() {
        CommandPaletteWindowController.shared.togglePalette()
    }

    @objc private func toggleMonitoringAction() {
        AppSettings.shared.monitoringActive.toggle()
        AppLogger.shared.info("Monitoring toggled: \(AppSettings.shared.monitoringActive)")
    }

    @objc private func openSettingsAction() {
        SettingsWindowController.shared.showSettings()
    }

    @objc private func quitAction() {
        NSApp.terminate(nil)
    }
}
