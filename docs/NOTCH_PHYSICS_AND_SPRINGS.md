# ClipNotch Physics & Spring Motion Guide

This guide describes the animation dynamics, spring curves, and state transitions used throughout the ClipNotch interactive interface.

---

## 1. Motion Profiles

ClipShot provides selectable motion personalities configured in `ClipNotchMotion`:

| Profile | Stiffness | Damping | Response Description |
| :--- | :--- | :--- | :--- |
| **Fluid (Default)** | Medium-High | Balanced | Snappy expansion with subtle overshoot, mimicking native macOS dynamic islands. |
| **Calm** | Low | High | Linear, measured expansion with zero overshoot for minimal visual distraction. |
| **Pulse** | High | Low | Energetic spring with visible oscillation for tactile feedback. |
| **Instant** | Infinite | Critical | 0-duration instantaneous state transitions for accessibility and performance. |

---

## 2. Idle Notch Dimensions & Scaling

To ensure comfortable visual balance on both MacBook hardware notches and external monitors:

- **Base Pill Dimensions**: Scaled up by **+12%** in idle state relative to legacy status bar icons for high visibility.
- **Corner Radii**: Dynamically clamped using continuous squircle geometry (`CornerRadius.continuous`).
- **OLED Protection**: Subtle pixel shifting prevents burn-in when stationary on high-brightness OLED displays.

---

## 3. Timing & Auto-Collapse Constants

- **Screenshot Preview Retention**: Default **4.5 seconds** before auto-collapsing to idle.
- **Hover Dismissal Delay**: **0.25 seconds** after pointer exit, providing a forgiving window for re-entry.
- **Hover Re-entry**: Immediately cancels pending collapse timers and restores the active capsule view.
