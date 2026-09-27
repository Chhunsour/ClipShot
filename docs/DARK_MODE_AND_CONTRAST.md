# Dark Mode & Contrast Compliance Guide

ClipShot interfaces adapt dynamically to macOS system appearance preferences (`NSAppearance`) while offering high-contrast options for accessibility compliance.

---

## 1. System Appearance Synchronization

ClipShot responds immediately to system appearance transitions (`NSAppearance.Name.darkAqua` and `NSAppearance.Name.aqua`):

```swift
@Environment(\.colorScheme) private var colorScheme
```

Users can also explicitly override appearance via ClipShot preferences:
- **System (Default)**: Automatically tracks macOS Light/Dark transitions.
- **Always Dark**: Preserves dark materials even when the host operating system is in Light Mode (ideal for media editing workflows).
- **Always Light**: Enforces light panels for high-ambient lighting environments.

---

## 2. Vibrant Translucency Materials

ClipShot utilizes macOS `NSVisualEffectView` materials for native desktop blending:

| Surface Component | Blending Material | Fallback for High Contrast |
| :--- | :--- | :--- |
| **Settings Window** | `.windowBackground` | Solid opaque background |
| **FloatingTool Panel** | `.hudWindow` | Opaque dark surface (`#121316`) |
| **Command Palette** | `.popover` | High-contrast dark sheet |
| **ClipNotch Body** | `.fullScreenUI` / Custom Metal | Solid obsidian black |

---

## 3. High Contrast Mode (`Increase Contrast`)

When the macOS accessibility setting **"Increase Contrast"** is enabled in `System Settings > Accessibility > Display`:
1. `NSWorkspace.shared.accessibilityDisplayShouldIncreaseContrast` returns `true`.
2. Subtle translucent materials are replaced with high-opacity borders (`lineWidth: 2.0`).
3. Border colors transition from soft white opacity (`0.06`) to solid high-contrast borders (`Color.white.opacity(0.40)`).
4. Secondary labels bump from 60% opacity to 85% opacity, achieving WCAG AAA compliance (≥ 7.0:1).

---

## 4. Color Palette Token Standards

ClipShot enforces strict semantic color tokens across all SwiftUI views:

```swift
// Semantic Tokens
Color.primaryText        // Contrast ratio ≥ 15:1 against dark surfaces
Color.secondaryText      // Contrast ratio ≥ 6:1 against dark surfaces
Color.accentBlue         // System accent with minimum 4.5:1 ratio
Color.warningYellow      // Warning status with dark border encapsulation
```
