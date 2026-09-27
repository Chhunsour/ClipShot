import Foundation
import ServiceManagement
import Combine

/// Manages modern macOS Launch at Login using SMAppService (macOS 13+).
public final class LaunchAtLoginManager: ObservableObject {
    public static let shared = LaunchAtLoginManager()

    @Published public private(set) var isEnabled: Bool = false

    public init() {
        refreshStatus()
    }

    /// Queries the current SMAppService registration status for the main application bundle.
    public func refreshStatus() {
        let status = SMAppService.mainApp.status
        self.isEnabled = (status == .enabled)
    }

    /// Registers or unregisters the app from macOS Login Items via SMAppService.
    /// - Parameter enable: True to launch automatically when the user logs in, false to disable.
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

    /// Toggles the current Launch at Login state.
    public func toggle() {
        setEnabled(!isEnabled)
    }
}
