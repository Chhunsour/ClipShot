# Battery & Energy Efficiency Guide

ClipShot is engineered from the ground up for minimal battery draw on Apple Silicon MacBooks (M1, M2, M3, M4) and Intel Mac laptops.

---

## Core Energy Principles

### 1. Zero Polling Architecture
Many traditional screenshot and clipboard utilities use persistent polling loops (e.g. checking Finder or pasteboard status every 100ms). This prevents the CPU from entering low-power sleep states (C-states).
ClipShot instead utilizes:
- **`FSEvents` / `kqueue` notifications**: The process sleeps until the macOS kernel wakes it upon a file event.
- **`NSPasteboard` change count checks**: Coalesced to fire only when active.

### 2. macOS App Nap & Window Occlusion
When ClipShot's capture overlays, history windows, and settings views are closed or occluded by other windows:
- macOS **App Nap** automatically throttles idle tasks.
- Background graphics contexts and rendering layers are unlinked, reducing GPU power draw to zero.
- Timers specify high tolerance margins (e.g. `tolerance: 0.2s`) to align with macOS power-efficient timer coalescing ticks.

### 3. ProMotion 120Hz Display Synchronization
ClipShot's ClipNotch and crosshairs animations run with `CADisplayLink` or SwiftUI fluid springs:
- Dynamically matches the native screen refresh rate: 120Hz on ProMotion displays for ultra-smooth feedback, and 60Hz on standard displays.
- Animations self-terminate immediately upon settling; no lingering display links consume energy once capsules are at rest.

### 4. Apple Silicon Neural Engine Acceleration
OCR text recognition is dispatched directly through Apple's `Vision.framework` to the on-die **Apple Neural Engine (ANE)**:
- Highly optimized matrix operations execute with a fraction of the thermal and energy cost of general CPU execution.
- Memory bandwidth spikes are minimized through shared unified memory architecture.
