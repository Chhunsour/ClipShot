# Troubleshooting & Diagnostic Guide

This guide covers common issues, edge cases, and recovery steps for ClipShot.

---

## 🔧 Frequently Encountered Scenarios

### 1. Screenshots are not being auto-copied to the clipboard
- **Check Monitoring Status**: Ensure monitoring is active. The menu bar icon should show active brackets; if paused, open the menu and click **Resume Monitoring** or press your configured hotkey.
- **Verify Screenshot Folder**: Open **Settings → General** and verify the watched folder matches macOS's default screenshot destination (`com.apple.screencapture location`).
- **Files & Folders Permission**: Verify ClipShot has access to the folder in **System Settings → Privacy & Security → Files and Folders**.

### 2. Crosshair capture screen shows black or blank canvas
- **Screen Recording Permission**: macOS requires explicit permission to read screen pixels.
- Open **System Settings → Privacy & Security → Screen & System Audio Recording**.
- Toggle ClipShot **OFF**, then **ON**, and restart ClipShot.
- Or reset the TCC permission from terminal:
  ```bash
  tccutil reset ScreenCapture com.clipshot.ClipShot
  ```

### 3. ClipNotch does not align with the MacBook camera notch
- ClipNotch automatically tracks display reconfiguration. If you unplug an external display, press `⌘ ⇧ 2` once or click the menu bar item to force a display re-scan.
- In **Settings → ClipNotch**, try switching between **Top Header** and **Below Menu Bar** modes.

### 4. Apple Music / Spotify controls do not respond in ClipNotch
- macOS requires Automation entitlements to send media transport events.
- Open **System Settings → Privacy & Security → Automation** and ensure **Music** and/or **Spotify** are checked under **ClipShot**.
- Or reset AppleEvents permission from terminal:
  ```bash
  tccutil reset AppleEvents com.clipshot.ClipShot
  ```

---

## 📜 Viewing Diagnostic Logs

ClipShot maintains local rotating diagnostic logs. To view real-time log output:
```bash
tail -f ~/Library/Logs/ClipShot/clipshot.log
```
Or open the log folder in Finder directly from **Settings → Advanced → Reveal Log Folder**.

---

## 🔄 Resetting to Factory Defaults

To completely reset ClipShot preferences:
1. Open **Settings → Advanced**.
2. Click **Reset to Defaults**.
3. Or delete the preference plist from terminal:
   ```bash
   defaults delete com.clipshot.ClipShot
   ```
