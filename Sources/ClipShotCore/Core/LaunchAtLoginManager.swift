import Foundation
import ServiceManagement
import Combine

/// Manages modern macOS Launch at Login using `SMAppService` (macOS 13 Ventura and later).
///
/// Under macOS 13+, Apple deprecated legacy helper daemon bundles and `SMLoginItemSetEnabled`.
/// Instead, `SMAppService.mainApp` allows the primary application bundle to register directly
/// with launchd as a user login item without requiring a separate embedded launcher app.
/// Registered items appear in System Settings → General → Login Items & Extensions, where
/// users retain final administrative control to allow or disallow background execution.
public final class LaunchAtLoginManager: ObservableObject {
    /// Shared singleton instance for application-wide launch at login coordination.
    public static let shared = LaunchAtLoginManager()

    /// Published flag reflecting whether the app is currently configured to launch at login.
    /// Observers can bind UI toggles directly to this property.
    @Published public private(set) var isEnabled: Bool = false

    /// Initializes the manager and synchronizes `isEnabled` against current system registration.
    public init() {
        refreshStatus()
    }

    /// Queries the current `SMAppService` registration status for the main application bundle.
    ///
    /// Evaluates `SMAppService.mainApp.status` against `.enabled`. Other states include
    /// `.notRegistered`, `.requiresApproval` (if the user disabled it in System Settings),
    /// and `.notFound` (in unsigned development builds).
    public func refreshStatus() {
        let status = SMAppService.mainApp.status
        self.isEnabled = (status == .enabled)
    }

    /// Registers or unregisters the app from macOS Login Items via `SMAppService`.
    ///
    /// If enabling, this method first defensively attempts unregistration if previously marked
    /// enabled to prevent duplicate registration state errors before calling `register()`.
    ///
    /// - Parameter enable: `true` to register for automatic launch upon user login; `false` to deregister.
    public func setEnabled(_ enable: Bool) {
        do {
            if enable {
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

    /// Toggles the current Launch at Login state between enabled and disabled.
    public func toggle() {
        setEnabled(!isEnabled)
    }
}

