# Screenshot History & Smart Cache Guide

ClipShot maintains an indexed, fast, local history archive of all your captures so you never lose an important screenshot.

---

## 🗄️ Storage Locations

ClipShot respects standard macOS application storage conventions:

- **Metadata Index**: `~/Library/Application Support/ClipShot/history.json`
  - Stores timestamp, file dimensions, file size, original URL, and trash state.
- **Thumbnail Cache**: `~/Library/Caches/ClipShot/thumbnails/`
  - Lightweight downscaled 320px PNG thumbnails for instantaneous scrolling.
- **Preserved Archive**: `~/Library/Application Support/ClipShot/Preserved/`
  - When *Clipboard-Only Mode* is active (original desktop file sent to Trash), ClipShot securely preserves a local history copy so you can still recover or re-copy it later.

---

## ⚙️ Retention & Pruning Policies

Configure retention behavior in **Settings → History**:

1. **Max Items Limit**:
   - `20 screenshots`
   - `50 screenshots`
   - `100 screenshots` (Default)
   - `500 screenshots`
   - `Unlimited`
2. **Age Expiration**:
   - `1 day`
   - `7 days`
   - `30 days` (Default)
   - `90 days`
   - `Never`

When limits are reached, oldest thumbnails and metadata are pruned automatically in background utility queues.

---

## 🔍 History Viewer (`⌘ ⇧ H`)

Press `⌘ ⇧ H` anytime to:
- Browse captures grouped by day and time.
- Search by filename or metadata.
- Re-copy image or file URL with one click.
- Launch Vision OCR or Annotation Markup.
- Drag-and-drop thumbnails into external apps.
