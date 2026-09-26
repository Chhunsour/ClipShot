# Floating Pin (Stay-On-Top Reference) Guide

ClipShot allows you to pin any screenshot as a floating, borderless reference panel that stays on top of all application windows.

---

## 📌 Use Cases

- **Design Comparison**: Pin a Figma mockup or UI design directly over your Xcode or VS Code window to match layout implementation down to the pixel.
- **Code Snippets & Specs**: Keep API contracts, database schemas, or StackOverflow code snippets visible while programming without sacrificing screen real estate.
- **Meeting Notes & Dashboards**: Keep meeting notes, monitoring metrics, or sprint tasks anchored on screen while working.

---

## ✨ Features & Controls

| Feature | Description |
| :--- | :--- |
| **Stay-on-Top Floating** | Floats at `NSWindow.Level.floating` above browser tabs and IDE windows. |
| **Non-Activating Window** | Clicking or dragging the pinned window does not steal keyboard focus from your active app. |
| **Variable Opacity** | Adjust transparency (25%, 50%, 75%, 100%) to see the underlying editor or document through the screenshot. |
| **Aspect-Ratio Lock** | Drag corners to resize freely while maintaining exact aspect ratio. |
| **Move Anywhere** | Drag by clicking anywhere on the image background (`isMovableByWindowBackground = true`). |

---

## 🎯 How to Pin a Screenshot

- **From ClipNotch**: Click the **Pin** icon (`pin.fill`) on the active capture capsule.
- **From Floating Preview**: Click the pin icon on the bottom corner overlay.
- **From Command Palette (`⌥ Space`)**: Select **Pin Last Screenshot**.
- **To Dismiss**: Hover over the pinned image and click the `×` button or press `Esc`.
