# Multi-Monitor & External Display Setup Guide

ClipShot provides full multi-display support across built-in MacBook screens, external 4K/5K displays (like Apple Studio Display and Pro Display XDR), ultrawide monitors, and Sidecar iPads.

---

## Display Topologies & Mixed DPI

macOS supports arbitrary desktop configurations where screens can differ in resolution, scale factor, and orientation. ClipShot seamlessly handles these differences:

### 1. Mixed Scale Factors (Retina @2x vs Standard @1x)
- When capturing a region spanning or moving between a 2x Retina MacBook screen and a 1x 1080p external monitor, ClipShot samples coordinates in point space (`CGPoint` / `CGRect`) and renders pixels using the source display's backing scale factor.
- Exported images maintain pixel-perfect sharpness without blurriness or unintended downsampling.

### 2. Multi-Display Coordinate Systems
- macOS sets the bottom-left of the primary display as `(0, 0)`, with Y-coordinates increasing upwards.
- CoreGraphics uses a top-left origin coordinate system.
- ClipShot's `DisplayTrackingService` handles bidirectional coordinate mapping so crosshairs, loupe magnifiers, and measurements remain accurately calibrated regardless of which monitor they are on.

### 3. Display Hot-Plugging & Reconnection
- If an external display is disconnected or plugged in, `DisplayTrackingService` receives `NSApplication.didChangeScreenParametersNotification`.
- Active ClipNotch instances automatically re-anchor to the primary monitor or target display without requiring an application restart.
