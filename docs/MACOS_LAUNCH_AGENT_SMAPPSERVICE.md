# macOS Launch at Login Architecture with SMAppService

Automatic application launch at user login is a critical feature for system utilities like ClipShot that monitor screenshot activity in the background. Modern macOS (13 Ventura, 14 Sonoma, 15 Sequoia) fundamentally overhauled this subsystem.

---

## 1. Evolution: Legacy vs Modern Architecture

| Feature | Legacy macOS (≤ 12 Monterey) | Modern macOS (≥ 13 Ventura) |
| :--- | :--- | :--- |
| **API** | `SMLoginItemSetEnabled` | `SMAppService.mainApp` |
| **Structure** | Embedded Launcher `.app` bundle in `Contents/Library/LoginItems/` | Main application bundle registers directly |
| **Visibility** | Obscure, often unlisted or hidden | Explicit entry in System Settings → Login Items |
| **User Control** | Registry write; user had to delete plist | User can toggle or revoke at any time |
| **Sandboxing** | Required complex XPC or mach service IPC | Fully compatible with App Sandbox |

---

## 2. SMAppService Lifecycle & States

`SMAppService.mainApp.status` returns one of four discrete states:

```swift
switch SMAppService.mainApp.status {
case .notRegistered:
    // App is not configured to start automatically at login
    break
case .enabled:
    // Active and managed by launchd for the current user
    break
case .requiresApproval:
    // User explicitly toggled off the app in System Settings → Login Items
    // Programmatic registration calls will not override user refusal
    break
case .notFound:
    // Bundle identifier or signature cannot be verified (e.g., unsigned local debug build)
    break
@unknown default:
    break
}
```

---

## 3. ClipShot Implementation & Defensive Registration

ClipShot encapsulates launch-at-login state management in `LaunchAtLoginManager.swift`:

```swift
public func setEnabled(_ enable: Bool) {
    do {
        if enable {
            // Defensive unregistration prevents duplicate state errors
            if SMAppService.mainApp.status == .enabled {
                try? SMAppService.mainApp.unregister()
            }
            try SMAppService.mainApp.register()
            AppLogger.shared.info("Enabled Launch at Login via SMAppService")
        } else {
            try SMAppService.mainApp.unregister()
            AppLogger.shared.info("Disabled Launch at Login via SMAppService")
        }
    } catch {
        AppLogger.shared.error("Failed to update Launch at Login: \(error.localizedDescription)")
    }

    refreshStatus()
}
```

### Key Technical Best Practices:
1. **Defensive Deregistration**: Before calling `register()`, unregistering prevents `kSMErrorAlreadyRegistered` errors when upgrading app binaries or migrating settings.
2. **Combine Reactivity**: `isEnabled` is declared `@Published` on `ObservableObject`, allowing SwiftUI settings views to bind directly with automatic UI synchronization.
3. **No Embedded Helpers**: Eliminating separate helper bundles shrinks the binary footprint and simplifies code signing notarization pipelines.
