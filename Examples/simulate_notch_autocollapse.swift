#!/usr/bin/env swift
import Foundation

print("--- ClipShot: ClipNotch Auto-Collapse State Machine & Timer Simulator ---")

enum NotchState: String {
    case hidden
    case peek
    case expanded
    case pinned
}

final class MockNotchController {
    var state: NotchState = .hidden
    var isHovered: Bool = false
    var isPinned: Bool = false
    var collapseTimerScheduled: Bool = false
    var remainingTimerDuration: Double = 0.0

    let autoCollapseDelay: Double = 2.0 // seconds

    func mouseEntered() {
        isHovered = true
        if collapseTimerScheduled {
            print("  [Event] Mouse Entered -> Cancelling pending collapse timer")
            collapseTimerScheduled = false
            remainingTimerDuration = 0.0
        }

        if state == .hidden {
            state = .peek
            print("  [State] Transition: .hidden -> .peek (hover trigger)")
        }
    }

    func expandAction() {
        if state != .pinned {
            state = .expanded
            print("  [State] Transition: -> .expanded (user click/action)")
        }
    }

    func togglePin() {
        isPinned.toggle()
        if isPinned {
            state = .pinned
            collapseTimerScheduled = false
            remainingTimerDuration = 0.0
            print("  [State] Notch PINNED: Auto-collapse disabled indefinitely")
        } else {
            state = .expanded
            print("  [State] Notch UNPINNED: Normal auto-collapse policy restored")
            if !isHovered {
                scheduleCollapse()
            }
        }
    }

    func mouseExited() {
        isHovered = false
        print("  [Event] Mouse Exited")
        if state != .pinned && state != .hidden {
            scheduleCollapse()
        }
    }

    private func scheduleCollapse() {
        collapseTimerScheduled = true
        remainingTimerDuration = autoCollapseDelay
        print("  [Timer] Scheduled auto-collapse in \(autoCollapseDelay)s")
    }

    func tick(seconds: Double) {
        guard collapseTimerScheduled else { return }
        remainingTimerDuration -= seconds
        if remainingTimerDuration <= 0 {
            collapseTimerScheduled = false
            remainingTimerDuration = 0.0
            let previous = state
            state = .hidden
            print("  [Timer Expired] Auto-collapse triggered! Transition: .\(previous) -> .hidden")
        } else {
            print("  [Timer Tick] Pending collapse: \(String(format: "%.1f", remainingTimerDuration))s remaining")
        }
    }
}

let controller = MockNotchController()

print("\n1. Simulation: Mouse enters notch area from top edge")
controller.mouseEntered()

print("\n2. Simulation: User expands notch to view screenshot history carousel")
controller.expandAction()

print("\n3. Simulation: Mouse leaves notch area while unpinned")
controller.mouseExited()

print("\n4. Simulation: Time advances 1.0 second (halfway through cooldown)")
controller.tick(seconds: 1.0)

print("\n5. Simulation: User moves mouse back before timeout expires (aborts collapse)")
controller.mouseEntered()

print("\n6. Simulation: User pins the notch")
controller.togglePin()

print("\n7. Simulation: Mouse leaves while pinned")
controller.mouseExited()
controller.tick(seconds: 2.5)
print("  Current State: .\(controller.state) (Must remain .pinned)")

print("\n8. Simulation: User unpins notch while mouse is away")
controller.togglePin()
controller.tick(seconds: 1.0)
controller.tick(seconds: 1.0)
print("  Final State: .\(controller.state) (Cleanly collapsed to .hidden)")

print("\nArchitectural Rationale: Cooldown timer debounce with cancellation on re-entry eliminates jittery notch fluttering while preserving screen real estate.")
