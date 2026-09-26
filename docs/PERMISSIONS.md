# macOS System Permissions Guide

ClipShot requires minimal macOS system permissions to operate seamlessly. This document explains each required permission, why ClipShot asks for it, and how to grant or verify access in **macOS 14 (Sonoma)** and **macOS 15 (Sequoia)**.

---

## 📋 Overview of Permissions

| Permission | Required? | Why ClipShot Needs It |
| :--- | :---: | :--- |
| **Screen & System Audio Recording** | **Yes** (for active capture) | Enables interactive crosshair selection (`⌘ ⇧ 2`), window capture, magnifier loupe, and screen recording. |
| **Files & Folders / Desktop** | **Yes** (for auto-clipboard) | Allows the `FSEvents` engine to read newly written screenshot files from your screenshot folder (e.g. `~/Desktop`). |
| **Notifications** | Optional | Displays brief notifications when a screenshot is copied to the clipboard or when an action completes. |
| **Automation / Apple Events** | Optional | Allows ClipNotch's media capsule to control track playback (play/pause/skip) in Apple Music or Spotify. |

---

## 🖥️ 1. Screen & System Audio Recording

### Why it is needed
Apple requires the Screen Recording entitlement (`CGPreflightScreenCaptureAccess`) for applications to read pixel buffers outside their own window context. ClipShot uses this for:
- Live pixel magnifier in the crosshair HUD.
- Window enumeration and shadow rendering.
- Offline Vision OCR text extraction.
- Recording video clips.

### How to Grant
1. Open **System Settings** → **Privacy & Security** → **Screen & System Audio Recording**.
2. Toggle the switch next to **ClipShot** to **ON**.
3. If prompted by macOS, restart ClipShot for changes to take effect.

> **Note for Developers**: When building with `swift run ClipShot` from the Terminal, macOS will associate the permission with your terminal application (e.g. `Terminal` or `iTerm2`). When running the packaged app from `./Scripts/build_app.sh`, macOS will associate the permission with `ClipShot.app`.

---

## 📁 2. Files & Folders Access

### Why it is needed
ClipShot listens to kernel `FSEvents` on your screenshot directory (default: `~/Desktop`). When macOS writes a new screenshot to disk, ClipShot opens the file to decode the raw bytes and copy them to `NSPasteboard`.

### How to Grant
1. Open **System Settings** → **Privacy & Security** → **Files and Folders**.
2. Locate **ClipShot** in the list.
3. Ensure **Desktop Folder** (or your custom screenshot directory) is enabled.

ClipShot also supports security-scoped bookmarks, which remember your access grant across app launches without re-prompting.

---

## 🔔 3. Notifications (Optional)

ClipShot can display native banner notifications when a capture is copied or when clipboard-only auto-trash completes.

To manage notification styles:
1. Open **System Settings** → **Notifications**.
2. Select **ClipShot** and configure alerts or banners as preferred.

---

## 🎵 4. Automation / Media Controls (Optional)

If you use ClipNotch to control playback in **Apple Music** or **Spotify**, macOS will display a prompt asking for permission to send Apple Events to that player on the first click of a transport button (Play/Pause/Skip).

To verify:
1. Open **System Settings** → **Privacy & Security** → **Automation**.
2. Expand **ClipShot** and ensure **Music** or **Spotify** is checked.

---

## 🛠️ Troubleshooting Permission Resets

If macOS does not register the permission prompt (common when developing or switching between debug and release builds), you can reset the TCC (Transparency, Consent, and Control) database for ClipShot using the terminal:

```bash
# Reset Screen Recording permission for ClipShot
tccutil reset ScreenCapture com.clipshot.ClipShot

# Reset Automation permission for ClipShot
tccutil reset AppleEvents com.clipshot.ClipShot
```
After resetting, re-launch ClipShot to trigger the system prompt fresh.
