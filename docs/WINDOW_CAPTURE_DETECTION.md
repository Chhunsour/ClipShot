# Window Capture & Hierarchy Detection Guide

ClipShot provides single-click window capture with automatic window boundary detection, shadow trimming, and multi-display spatial mapping.

---

## 1. Window Querying & Discovery

ClipShot queries on-screen windows via CoreGraphics APIs:

```swift
let options: CGWindowListOption = [.optionOnScreenOnly, .excludeDesktopElements]
let windowListInfo = CGWindowListCopyWindowInfo(options, kCGNullWindowID) as? [[CFString: Any]]
```

### Filtering Heuristics
Not every window returned by the Window Server is a valid user-facing application window:
1. **Window Layer**: Only windows at `kCGNormalWindowLevel` (layer 0) are considered. Menu extras, status bars, and floating utility panels are excluded.
2. **Alpha & Opacity**: Transparent overlays (`alpha <= 0.05`) are discarded.
3. **Minimum Bounds**: Windows smaller than 32 × 32 pt (such as hidden helper windows) are ignored.
4. **Owner Process**: ClipShot's own transparent overlay panels and floating previews are filtered out using their process PID.

---

## 2. Window Shadow Handling

macOS applications render drop shadows around standard windows using CoreAnimation window backing stores. ClipShot provides an explicit user preference:

```swift
AppSettings.shared.includeWindowShadow: Bool
```

### Shadow Inclusion Modes
- **With Shadow (`true`)**: Captures the window along with its transparent gradient drop shadow (`kCGWindowImageDefault`). This produces images suitable for documentation and presentations against light or dark backdrops.
- **Without Shadow (`false`)**: Trims the outer shadow pixels (`kCGWindowImageBoundsIgnoreFraming`), cropping tightly to the exact window frame rect.

---

## 3. High-DPI & Multi-Monitor Window Capture

When a window spans across multiple displays with differing pixel densities (for example, a built-in 2x Retina display and an external 1x 1080p display):
- ClipShot queries the target display where the majority of the window rect resides (`screen.frame.intersection(windowRect)`).
- The capture engine requests CoreGraphics to render the bitmap at the native backing scale of the host display, ensuring text and iconography remain razor-sharp.

---

## 4. Permissions & Entitlements

Window capture requires **Screen Recording** permission granted in:
`System Settings > Privacy & Security > Screen Recording`

If access has not yet been granted, `CGPreflightScreenCaptureAccess()` returns `false`, prompting ClipShot to present an inline permission onboarding panel rather than attempting an empty capture.
