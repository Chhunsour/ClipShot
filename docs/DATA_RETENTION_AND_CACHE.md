# Data Retention & Cache Management Guide

ClipShot provides flexible local data retention policies to balance fast search/retrieval against disk footprint.

---

## 1. History Retention Limits

Retention is configurable in **Preferences ▶ History & Archive**:

### Count-Based Limits (`HistoryLimit`)
- **20 items**: Minimal footprint for casual users.
- **50 items**: Recommended for everyday workflows.
- **100 items (Default)**: Standard buffer balancing instant search with low memory usage.
- **200 items**: Power-user archive.
- **Unlimited**: Retains all items subject to time-based retention pruning.

### Time-Based Retention (`HistoryRetention`)
- **1 day**: Automatically prunes captures older than 24 hours.
- **7 days**: Retains the past week of captures.
- **30 days (Default)**: Keeps captures for one month.
- **90 days**: Quarterly archive retention.
- **Never (Unlimited)**: Retains records permanently until manually deleted.

---

## 2. Disk Storage Locations

| Subsystem | Path | Description |
| :--- | :--- | :--- |
| **History Database** | `~/Library/Application Support/ClipShot/history.json` | JSON archive of metadata records. |
| **Thumbnail Cache** | `~/Library/Caches/com.clipshot.ClipShot/Thumbnails/` | Downscaled 300px cached previews. |
| **Diagnostic Logs** | `~/Library/Logs/ClipShot/clipshot.log` | Rolling diagnostic logs (max 3 files × 2MB). |
| **Preserved Copies** | `~/Library/Application Support/ClipShot/Preserved/` | Optional local copies of trashed screenshots. |

---

## 3. Preserved Deleted Screenshot Copies

When `storeDeletedScreenshotCopies` is enabled, ClipShot preserves a local compressed copy in its Application Support sandbox if the user deletes the original file from the Desktop or screenshot folder. This ensures screenshots remain accessible from history even if cleaned up from disk.
