# Global Hotkey Mapping Reference

ClipShot provides system-wide global hotkeys registered via the macOS Carbon Event Manager APIs, ensuring low-latency invocation regardless of the active frontmost application.

---

## 1. Supported Hotkey Actions

| Action Identifier | Action Title | Default Shortcut | Purpose |
| :--- | :--- | :--- | :--- |
| `capture_overlay` | Capture Overlay (Full Suite) | `⌥ + Space` | Activates interactive crosshair with loupe and measurement tools. |
| `capture_area` | Capture Area | `⇧ + ⌘ + 1` | Immediate rectangular area selection mode. |
| `capture_screen` | Capture Full Screen | `⇧ + ⌘ + 2` | Instant capture of primary or selected display. |
| `capture_window` | Capture Window | `⇧ + ⌘ + W` | Window hover detection and isolated window capture. |
| `command_palette` | Command Palette | `⇧ + ⌘ + K` | Quick search across all ClipShot actions, tools, and recents. |
| `open_history` | Screenshot History | `⇧ + ⌘ + H` | Opens searchable history archive viewer. |
| `copy_last_screenshot` | Copy Last Screenshot | Customizable | Re-copies the most recently captured image to pasteboard. |
| `ocr_last_screenshot` | OCR Last Screenshot | Customizable | Extracts text from the latest screenshot via Apple Vision OCR. |
| `pinLastScreenshot` | Pin Last Screenshot | Customizable | Floats latest screenshot on top of all windows. |
| `toggle_monitoring` | Pause / Resume Monitoring | Customizable | Temporarily disables or resumes FSEvents screenshot ingestion. |

---

## 2. Carbon EventHotKey Architecture

- **Registration API**: Uses `RegisterEventHotKey` with uniquely mapped 32-bit signatures.
- **Event Handler**: Installed via `InstallEventHandler` targeting `kEventClassKeyboard` and `kEventHotKeyPressed`.
- **System Shortcut Safety**: ClipShot intentionally defaults to non-conflicting modifiers to avoid hijacking Apple's native `⌘ + ⇧ + 3` / `⌘ + ⇧ + 4` / `⌘ + ⇧ + 5` shortcuts.
