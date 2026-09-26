# Frequently Asked Questions (FAQ)

---

### 1. Is ClipShot really 100% free and open-source?
**Yes.** ClipShot is released under the permissive [MIT License](LICENSE). There are no paid tiers, no subscriptions, no locked features, and no license keys.

### 2. Does ClipShot transmit any data or telemetry?
**No.** ClipShot makes **zero** outbound network requests. All image decoding, text recognition (OCR), history indexing, and album art color analysis run entirely locally on your Mac.

### 3. How does ClipShot achieve 0.0% idle CPU usage?
Unlike tools that run periodic polling timers (e.g. checking folder contents every 500ms), ClipShot registers directly with the Darwin kernel `FSEvents` subsystem. When no screenshot is being taken, ClipShot's thread sleeps and consumes zero CPU cycles and zero battery.

### 4. Does ClipShot work on external monitors without a hardware notch?
**Yes.** ClipShot's `DisplayTrackingService` detects whether the active display has a physical camera notch. On non-notched screens or external monitors, ClipNotch smoothly docks into the top system menu bar or functions in **Free Floating Island** mode based on your preference.

### 5. Can I keep using my muscle memory for `⌘ ⇧ 4` and `⌘ ⇧ 3`?
**Yes.** ClipShot does not override or disable macOS's built-in shortcuts. When you take a screenshot with `⌘ ⇧ 4` or `⌘ ⇧ 3`, ClipShot's kernel event listener catches the file instantly (<100ms) and places the raw image bytes directly on your clipboard.

### 6. What is "Clipboard-Only Mode"?
In **Settings → General**, you can enable *Clipboard-Only Mode* (`trash`). When active, ClipShot copies the image bytes to your clipboard immediately and moves the temporary screenshot file from your Desktop directly to the macOS Trash, keeping your workspace spotless. A copy is safely preserved in local history if you need it later.

### 7. Does OCR support code snippets and indentation?
**Yes.** ClipShot's OCR engine is tuned to preserve tab indentation, curly braces, and code structure, making it ideal for grabbing code from video tutorials, design mockups, and presentations.
