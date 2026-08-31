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

    public func refreshStatus() {
        let status = SMAppService.mainApp.status
        self.isEnabled = (status == .enabled)
    }

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

    public func toggle() {
        setEnabled(!isEnabled)
    }
}
