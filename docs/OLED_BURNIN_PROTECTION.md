# OLED & Mini-LED Burn-In Mitigation Strategy

Modern macOS hardware and external monitors increasingly use OLED, QD-OLED, and Mini-LED display panels. Persistent static interface elements (such as notch headers, floating tool buttons, and status icons) carry a potential risk of uneven sub-pixel degradation over extended periods.

ClipShot implements several deliberate architectural safeguards to protect high-end display panels.

---

## 1. Pixel Shifting (Micro-Displacement)

For persistent widgets like the **ClipNotch Header** and **FloatingToolPanel**, ClipShot applies periodic micro-pixel shifts:

- **Magnitude**: ±1.0 to ±2.0 logical points (2 to 4 physical device pixels on 2x Retina displays).
- **Interval**: Occurs quietly every 180 seconds during periods of system inactivity.
- **Direction**: Cycles continuously through an 8-point orbital pattern:
  `(+1, 0) -> (+1, +1) -> (0, +1) -> (-1, +1) -> (-1, 0) -> (-1, -1) -> (0, -1) -> (+1, -1)`
- **Perception**: Imperceptible to the human eye during active workstation usage, yet sufficient to evenly distribute sub-pixel luminance load across neighboring LED diodes.

---

## 2. Idle Dimming & Auto-Collapse

Static UI components avoid sustained high-contrast luminance:

| Component | Default Behavior | Energy / Burn-In Protection |
| :--- | :--- | :--- |
| **ClipNotch** | Collapses to compact 184 × 34 pt pill | Dimmed border alpha (0.02 to 0.05) |
| **FloatingTool** | Auto-collapses after 3s inactivity | Drops to transparent circle with 0.40 opacity |
| **Video Capsule** | Live window stream | Suspends rendering when source window is occluded |
| **Preview Panel** | Floating thumbnail | Auto-dismisses after 5.0 seconds |

---

## 3. Dark Theme Material Calibration

ClipShot interfaces use true black backgrounds with soft, low-luminance specular gradients:
- Surface fills: `Color(red: 14/255, green: 15/255, blue: 18/255)`
- Border highlights: `Color.white.opacity(0.06)`
- Pure white (`#FFFFFF`) is strictly reserved for primary typography and active toggle indicators, preventing large patches of saturated static white pixels.

---

## 4. Reduced Energy Footprint

When displays go to sleep or screen saver activates:
1. `NSApplication.didResignActiveNotification` and display sleep notifications pause animation timers.
2. Metal and CoreAnimation frame drawing is suspended entirely until user wake events are received.
