#!/usr/bin/env swift
import Foundation

print("--- ClipShot: Harmonic Oscillator Spring Physics Simulator ---")

struct SpringSystem {
    let mass: Double       // kg (typically 1.0)
    let stiffness: Double  // N/m (spring constant k)
    let damping: Double    // N·s/m (damping coefficient c)

    var naturalFrequency: Double {
        sqrt(stiffness / mass)
    }

    var dampingRatio: Double {
        damping / (2.0 * sqrt(stiffness * mass))
    }

    var classification: String {
        let zeta = dampingRatio
        if abs(zeta - 1.0) < 0.001 {
            return "Critically Damped (Fastest settling, zero overshoot)"
        } else if zeta < 1.0 {
            return "Underdamped (Bouncy with oscillations)"
        } else {
            return "Overdamped (Sluggish without overshoot)"
        }
    }
}

// Compare three configurations relevant to ClipNotch expansion animation
let presets: [(name: String, spring: SpringSystem)] = [
    ("ClipNotch Snappy (Critically Damped)", SpringSystem(mass: 1.0, stiffness: 300.0, damping: 2.0 * sqrt(300.0))),
    ("Bouncy Popover (Underdamped)", SpringSystem(mass: 1.0, stiffness: 300.0, damping: 18.0)),
    ("Smooth Fluid Panel (Slightly Overdamped)", SpringSystem(mass: 1.0, stiffness: 220.0, damping: 35.0))
]

let targetDisplacement = 180.0 // Expanding notch height from 0 to 180 pt
let dt = 1.0 / 60.0             // 60 Hz frame tick (16.67 ms)
let maxFrames = 36             // ~600ms observation window

for preset in presets {
    print("\nPreset: [\(preset.name)]")
    print(String(format: "  Mass: %.1f kg | Stiffness: %.1f N/m | Damping: %.2f", preset.spring.mass, preset.spring.stiffness, preset.spring.damping))
    print(String(format: "  Damping Ratio (ζ): %.3f -> %@", preset.spring.dampingRatio, preset.spring.classification))

    var position = 0.0
    var velocity = 0.0
    var settledFrame: Int?

    print(String(format: "  %-6@ %-12@ %-12@ %-12@", "Frame", "Time(ms)", "Height(pt)", "Velocity"))
    print("  " + String(repeating: "-", count: 48))

    for frame in 0...maxFrames {
        let timeMs = Double(frame) * dt * 1000.0
        
        // Semi-implicit Euler integration
        let springForce = -preset.spring.stiffness * (position - targetDisplacement)
        let dampingForce = -preset.spring.damping * velocity
        let acceleration = (springForce + dampingForce) / preset.spring.mass

        velocity += acceleration * dt
        position += velocity * dt

        if frame % 4 == 0 || frame == maxFrames {
            print(String(format: "  %-6d %-12.1f %-12.2f %-12.2f", frame, timeMs, position, velocity))
        }

        if settledFrame == nil && abs(position - targetDisplacement) < 0.5 && abs(velocity) < 2.0 {
            settledFrame = frame
        }
    }

    if let sf = settledFrame {
        let settleMs = Double(sf) * dt * 1000.0
        print(String(format: "  ✨ Settled within 0.5pt threshold at frame %d (%.1f ms)", sf, settleMs))
    } else {
        print("  ⏳ Still settling beyond 600ms window")
    }
}
