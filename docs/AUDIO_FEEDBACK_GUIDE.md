# Audio Feedback Architecture Guide

ClipShot provides subtle, non-intrusive sound feedback for screenshot capture and clipboard operations.

---

## 1. System Sound Integration

Rather than bundling heavy audio asset files, ClipShot leverages macOS built-in system sound libraries:

- **Primary Sound**: `NSSound(named: "Tink")` — Short, crisp high-frequency tone confirming successful clipboard writes.
- **Fallback Sound**: `NSSound(named: "Pop")` — Low-frequency soft tone used if "Tink" is unavailable.

---

## 2. Audio Triggers

Sound effects occur on specific user actions:

| Trigger Event | Subsystem | Default State | Description |
| :--- | :--- | :--- | :--- |
| **Screenshot Auto-Copy** | `ClipboardManager` | Disabled (opt-in) | Plays when a detected screenshot is written to pasteboard. |
| **Color Picker Copy** | `ColorPickerService` | Enabled | Plays when sampled pixel color is copied to clipboard. |
| **OCR Text Copy** | `OCRResultView` | Enabled | Plays when extracted text is copied to clipboard. |

---

## 3. Configuration & Silence Compliance

Audio feedback is controlled globally via `AppSettings.shared.playSoundOnCopy`:

- **Settings UI**: Can be toggled under **Preferences ▶ General ▶ Play sound on copy**.
- **System Volume & Mute**: Adheres to macOS system volume levels and Do Not Disturb (Focus) profiles automatically.
