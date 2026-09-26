# Configuration & AppSettings Reference

All ClipShot user configurations are managed via `AppSettings` and persisted automatically in macOS `UserDefaults` under domain `com.clipshot.ClipShot`.

---

## ⚙️ Core Configuration Keys

| Preference Key | Type | Default Value | Description |
| :--- | :---: | :---: | :--- |
| `isMonitoringEnabled` | `Bool` | `true` | Enables FSEvents kernel filesystem listening for new screenshots. |
| `detectionMode` | `String` | `"screenshots_only"` | `"screenshots_only"` (macOS naming patterns) or `"all_images"`. |
| `clipboardMode` | `String` | `"image_only"` | `"image_only"` (raw bitmap bytes) or `"image_and_file"`. |
| `afterCopyAction` | `String` | `"keep"` | `"keep"` (preserves desktop file) or `"trash"` (sends file to Trash). |
| `playSoundOnCopy` | `Bool` | `true` | Plays subtle audio feedback when image is successfully copied. |
| `launchAtLogin` | `Bool` | `false` | Registers background launch helper via `SMAppService`. |

---

## 🏝️ ClipNotch Preferences

| Preference Key | Type | Default Value | Options |
| :--- | :---: | :---: | :--- |
| `clipNotchEnabled` | `Bool` | `true` | Toggles the Dynamic Notch companion interface. |
| `clipNotchColorway` | `String` | `"Prism"` | 14 Palettes (Prism, Aurora, Ember, Album Aura, etc.). |
| `clipNotchFinish` | `String` | `"Obsidian"` | 6 Finishes (Obsidian, Glass, Bloom, Titanium, etc.). |
| `clipNotchMotionProfile`| `String` | `"Fluid"` | 5 Profiles (Calm, Fluid, Snappy, Pulse, Bouncy). |
| `clipNotchSizing` | `String` | `"Normal"` | Compact, Normal, Large, Extra Large, Ultra Wide, Studio. |
| `clipNotchPlacement` | `String` | `"TopHeader"` | Top Header, Below Menu Bar, Free Floating Island. |
| `clipNotchMusicEnabled`| `Bool` | `true` | Enables dynamic Now Playing music transport capsule. |

---

## 🕒 History & Cache Preferences

| Preference Key | Type | Default Value | Options |
| :--- | :---: | :---: | :--- |
| `historyEnabled` | `Bool` | `true` | Automatically index captures in local history. |
| `historyLimit` | `Int` | `100` | Max items retained (20, 50, 100, 500, unlimited 0). |
| `historyRetention` | `Int` | `30` | Auto-prune cutoff in days (1, 7, 30, 90, never 0). |
