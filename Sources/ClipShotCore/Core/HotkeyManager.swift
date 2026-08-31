import Foundation
import AppKit
import Carbon

/// Global action identifier for hotkeys.
public enum HotkeyAction: String, CaseIterable, Identifiable, Codable {
    case captureOverlay = "capture_overlay"
    case captureArea = "capture_area"
    case captureScreen = "capture_screen"
    case captureWindow = "capture_window"
    case copyLastScreenshot = "copy_last_screenshot"
    case openHistory = "open_history"
    case commandPalette = "command_palette"
    case ocrLastScreenshot = "ocr_last_screenshot"
    case pinLastScreenshot = "pin_last_screenshot"
    case toggleMonitoring = "toggle_monitoring"

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .captureOverlay: return "Capture Overlay (Full Suite)"
        case .captureArea: return "Capture Area"
        case .captureScreen: return "Capture Full Screen"
        case .captureWindow: return "Capture Window"
        case .copyLastScreenshot: return "Copy Last Screenshot"
        case .openHistory: return "Screenshot History"
        case .commandPalette: return "Command Palette"
        case .ocrLastScreenshot: return "OCR Last Screenshot"
        case .pinLastScreenshot: return "Pin Last Screenshot"
        case .toggleMonitoring: return "Pause / Resume Monitoring"
        }
    }
}

/// Global Hotkey Manager using Carbon Event HotKey APIs.
public final class HotkeyManager: @unchecked Sendable {
    public static let shared = HotkeyManager()

    private var hotKeyRefs: [HotkeyAction: EventHotKeyRef] = [:]
    private var actionHandlers: [HotkeyAction: () -> Void] = [:]
    private var eventHandlerRef: EventHandlerRef?

    public init() {
        installCarbonEventHandler()
    }

    deinit {
        unregisterAll()
        if let handler = eventHandlerRef {
            RemoveEventHandler(handler)
        }
    }

    // MARK: - Registration

    public func registerHandler(for action: HotkeyAction, handler: @escaping () -> Void) {
        actionHandlers[action] = handler
    }

    public func registerHotKey(action: HotkeyAction, keyCode: UInt32, modifiers: UInt32) {
        // Unregister existing if any
        unregisterHotKey(for: action)

        var hotKeyRef: EventHotKeyRef?
        let hotKeyID = EventHotKeyID(signature: OSType(0x43534854), id: UInt32(action.hashValue & 0x7FFFFFFF))

        let status = RegisterEventHotKey(
            keyCode,
            modifiers,
            hotKeyID,
            GetEventDispatcherTarget(),
            0,
            &hotKeyRef
        )

        if status == noErr, let ref = hotKeyRef {
            hotKeyRefs[action] = ref
            AppLogger.shared.info("Registered global hotkey for: \(action.rawValue)")
        } else {
            AppLogger.shared.warning("Failed to register hotkey for \(action.rawValue), status: \(status)")
        }
    }

    public func unregisterHotKey(for action: HotkeyAction) {
        if let ref = hotKeyRefs.removeValue(forKey: action) {
            UnregisterEventHotKey(ref)
        }
    }

    public func unregisterAll() {
        for (_, ref) in hotKeyRefs {
            UnregisterEventHotKey(ref)
        }
        hotKeyRefs.removeAll()
    }

    // MARK: - Carbon Handler

    private func installCarbonEventHandler() {
        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))

        let callback: EventHandlerProcPtr = { (nextHandler, theEvent, userData) -> OSStatus in
            var hotKeyID = EventHotKeyID()
            let status = GetEventParameter(
                theEvent,
                EventParamName(kEventParamDirectObject),
                EventParamType(typeEventHotKeyID),
                nil,
                MemoryLayout<EventHotKeyID>.size,
                nil,
                &hotKeyID
            )

            if status == noErr {
                for (action, _) in HotkeyManager.shared.hotKeyRefs {
                    let expectedID = UInt32(action.hashValue & 0x7FFFFFFF)
                    if hotKeyID.id == expectedID {
                        DispatchQueue.main.async {
                            HotkeyManager.shared.actionHandlers[action]?()
                        }
                        return noErr
                    }
                }
            }

            return CallNextEventHandler(nextHandler, theEvent)
        }

        InstallEventHandler(
            GetEventDispatcherTarget(),
            callback,
            1,
            &eventType,
            nil,
            &eventHandlerRef
        )
    }
}
