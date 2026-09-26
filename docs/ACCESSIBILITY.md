# Accessibility (a11y) Design & Features

ClipShot is built with deep respect for macOS accessibility guidelines, ensuring power-user features are accessible to all users.

---

## ♿ Core Accessibility Features

### 1. VoiceOver Support
- Status bar item provides explicit accessibility descriptions (`accessibilityDescription = "ClipShot Menu"`).
- Capture overlay crosshairs announce width, height, and active tool selections.
- History thumbnails include timestamp, dimension, and file size accessibility labels.

### 2. Full Keyboard Navigation
- All major features are accessible without a mouse via customizable global hotkeys (`⌘ ⇧ 2`, `⌥ Space`, `⌘ ⇧ H`).
- The Command Palette (`⌥ Space`) allows 100% keyboard-driven execution of capture modes, settings, and OCR actions with arrow keys and `Enter`.
- Selection rectangles can be nudged by 1px or 10px using standard arrow keys (`←`, `→`, `↑`, `↓`).

### 3. Visual Contrast & Legibility
- All 14 ClipNotch colorways and 6 finishes are calibrated to maintain minimum 4.5:1 WCAG contrast for text labels.
- Crosshair dimension badges render with high-contrast semi-opaque black backgrounds and bold monospace fonts.
- Supports macOS System Appearance (automatically following Light Mode and Dark Mode).

### 4. Reduced Motion
- Notch spring animations respect the user's motion preferences, offering a **Calm** profile with reduced elasticity and zero overshoot for users sensitive to motion effects.
