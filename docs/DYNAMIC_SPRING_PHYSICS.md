# Dynamic Spring Physics & Fluid Motion in ClipNotch

Interfaces in macOS feel physical and responsive when transitions are driven by mathematical harmonic oscillators rather than rigid linear or cubic-bezier easing curves. ClipNotch utilizes dynamic spring animations for hover expansions, screenshot pill reveals, and media recording states.

---

## 1. The Physics: Harmonic Oscillator Model

A mass-spring-damper system is governed by the second-order differential equation:

$$m \frac{d^2x}{dt^2} + c \frac{dx}{dt} + k x = 0$$

Where:
- $m$: **Mass** (inertia of the interface element, typically $1.0\text{ kg}$)
- $k$: **Stiffness** (spring constant defining retraction force, $\text{N/m}$)
- $c$: **Damping** (resistance coefficient dissipating kinetic energy, $\text{N}\cdot\text{s/m}$)

---

## 2. Damping Ratio Classification ($\zeta$)

The damping ratio $\zeta$ controls oscillation behavior:

$$\zeta = \frac{c}{2\sqrt{k \cdot m}}$$

| Damping Ratio | Regime | Behavior in UI |
| :--- | :--- | :--- |
| $\zeta < 1.0$ | **Underdamped** | Oscillates around the target value before settling. Creates playful bounce effects. |
| $\zeta = 1.0$ | **Critically Damped** | **Reaches equilibrium in the minimum possible time with zero overshoot.** Optimal for toolbar and notch expansion. |
| $\zeta > 1.0$ | **Overdamped** | Slow, non-oscillating approach. Feels heavy and sluggish if overused. |

---

## 3. Semi-Implicit Euler Integration for ProMotion (120 Hz)

On MacBook Pro Liquid Retina XDR displays with ProMotion variable refresh rates (up to 120 Hz), frame timesteps $\Delta t$ vary dynamically between $8.33\text{ ms}$ (120 Hz) and $16.67\text{ ms}$ (60 Hz).

Semi-implicit Euler integration updates velocity before position, guaranteeing numerical stability:

```swift
let springForce = -stiffness * (position - targetDisplacement)
let dampingForce = -damping * velocity
let acceleration = (springForce + dampingForce) / mass

velocity += acceleration * dt
position += velocity * dt
```

---

## 4. SwiftUI Spring Parameter Mapping

SwiftUI abstracts physical parameters into perceptual controls:
- **`response`**: Duration of one half-cycle in seconds:
  $$\text{response} = 2\pi \sqrt{\frac{m}{k}}$$
- **`dampingRatio`**: Direct dimensionless damping ratio $\zeta$.

```swift
// ClipNotch Snappy Transition Preset
withAnimation(.spring(response: 0.35, dampingRatio: 0.82)) {
    self.isExpanded = true
}
```

This configuration ensures the notch expands immediately when hovered, provides a subtle organic cushion upon reaching full width, and snaps shut cleanly upon mouse exit.
