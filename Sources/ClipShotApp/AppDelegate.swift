import Foundation
import AppKit
import SwiftUI
import Carbon
import ClipShotCore

/// Primary application delegate managing lifecycle, menu bar icon, FSEvents startup, and hotkeys.
@MainActor
public final class AppDelegate: NSObject, NSApplicationDelegate {

    public func applicationDidFinishLaunching(_ notification: Notification) {
        AppLogger.shared.info("ClipShot launched (version \(AppConfig.appVersion))")

        // 1. Configure activation policy (Accessory = Menu bar only by default)
        let showDock = AppSettings.shared.showDockIcon
        NSApp.setActivationPolicy(showDock ? .regular : .accessory)
        AppSettings.shared.applyAppearance()

        // 2. Setup Menu Bar Status Item
        MenuBarController.shared.setupStatusItem()

        // 3. Connect Preview Panel to Central Processor Actor
        Task {
            await ScreenshotProcessor.shared.setPreviewCallback { url, image, item in
                FloatingPreviewPanel.shared.show(image: image, fileURL: url, item: item)
            }
        }

        // 4. Start FSEvents Screenshot Monitoring if active
        if AppSettings.shared.monitoringActive {
            ScreenshotMonitor.shared.start()
        }

        ClipboardHistoryManager.shared.startMonitoring()

        // 5. Setup Hotkey Handlers
        setupGlobalHotkeys()

        // 6. Check and display Onboarding if first launch
        OnboardingWindowController.shared.showOnboardingIfNeeded()

        // 7. Update floating screen edge dock visibility
        FloatingToolPanel.shared.updateVisibility()

        // 8. Initialize ClipNotch overlay
        ClipNotchController.shared.setup()
    }

    public func applicationWillTerminate(_ notification: Notification) {
        AppLogger.shared.info("ClipShot terminating")
        ScreenshotMonitor.shared.stop()
        ClipboardHistoryManager.shared.stopMonitoring()
        HotkeyManager.shared.unregisterAll()
    }

    public func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if !flag {
            SettingsWindowController.shared.showSettings()
        }
        return true
    }

    private func setupGlobalHotkeys() {
        let hotkeyManager = HotkeyManager.shared

        // ⌘ ⇧ 2 -> Open Capture Overlay
        hotkeyManager.registerHandler(for: .captureOverlay) {
            CaptureOverlayController.shared.showOverlay()
        }
        hotkeyManager.registerHotKey(
            action: .captureOverlay,
            keyCode: 19, // '2' key
            modifiers: UInt32(cmdKey | shiftKey)
        )

        // ⌘ ⇧ H -> Open History
        hotkeyManager.registerHandler(for: .openHistory) {
            HistoryWindowController.shared.showHistory()
        }
        hotkeyManager.registerHotKey(
            action: .openHistory,
            keyCode: 4, // 'H' key
            modifiers: UInt32(cmdKey | shiftKey)
        )

        // ⌥ Space -> Open Command Palette
        hotkeyManager.registerHandler(for: .commandPalette) {
            CommandPaletteWindowController.shared.togglePalette()
        }
        hotkeyManager.registerHotKey(
            action: .commandPalette,
            keyCode: 49, // Spacebar
            modifiers: UInt32(optionKey)
        )

        hotkeyManager.registerHandler(for: .captureArea) {
            CaptureOverlayController.shared.showOverlay(initialMode: .area)
        }

        hotkeyManager.registerHandler(for: .captureScreen) {
            CaptureOverlayController.shared.showOverlay(initialMode: .screen)
        }

        hotkeyManager.registerHandler(for: .captureWindow) {
            CaptureOverlayController.shared.showOverlay(initialMode: .window)
        }

        hotkeyManager.registerHandler(for: .copyLastScreenshot) {
            guard let item = HistoryManager.shared.lastScreenshot,
                  let url = item.effectiveImageURL,
                  let image = ImageUtils.loadImage(at: url) else { return }
            ClipboardManager.shared.copy(image: image, fileURL: url)
            SoundManager.shared.playCopySound()
        }
    }
}
