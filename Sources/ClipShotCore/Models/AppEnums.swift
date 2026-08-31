import Foundation

/// Detection mode for identifying screenshots vs other images.
public enum DetectionMode: String, CaseIterable, Identifiable, Codable, Sendable {
    case screenshotsOnly = "screenshots_only"
    case allImages = "all_images"

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .screenshotsOnly:
            return "macOS screenshots only"
        case .allImages:
            return "Any new image in screenshot folder"
        }
    }
}

/// Clipboard representation format options.
public enum ClipboardMode: String, CaseIterable, Identifiable, Codable, Sendable {
    case imageOnly = "image_only"
    case imageAndFile = "image_and_file"
    case fileOnly = "file_only"

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .imageOnly:
            return "Image only"
        case .imageAndFile:
            return "Image + file reference"
        case .fileOnly:
            return "File reference only"
        }
    }
}

/// Action to perform on original screenshot file after auto-copying.
public enum AfterCopyAction: String, CaseIterable, Identifiable, Codable, Sendable {
    case keep = "keep"
    case trash = "trash"
    case deleteAfterDelay = "delete_after_delay"
    case ask = "ask"

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .keep:
            return "Keep screenshot file"
        case .trash:
            return "Move screenshot to Trash"
        case .deleteAfterDelay:
            return "Delete automatically after delay"
        case .ask:
            return "Ask from preview"
        }
    }
}

/// Screen corner for floating preview overlay.
public enum PreviewCorner: String, CaseIterable, Identifiable, Codable, Sendable {
    case bottomRight = "bottom_right"
    case bottomLeft = "bottom_left"
    case topRight = "top_right"
    case topLeft = "top_left"

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .bottomRight: return "Bottom Right"
        case .bottomLeft: return "Bottom Left"
        case .topRight: return "Top Right"
        case .topLeft: return "Top Left"
        }
    }
}

/// Detection sensitivity level for screenshot identification.
public enum DetectionSensitivity: String, CaseIterable, Identifiable, Codable, Sendable {
    case strict = "strict"
    case balanced = "balanced"
    case permissive = "permissive"

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .strict: return "Strict"
        case .balanced: return "Balanced"
        case .permissive: return "Permissive"
        }
    }
}

/// Appearance theme settings.
public enum AppearanceSetting: String, CaseIterable, Identifiable, Codable, Sendable {
    case system = "system"
    case light = "light"
    case dark = "dark"

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .system: return "System"
        case .light: return "Light"
        case .dark: return "Dark"
        }
    }
}

/// Max items to retain in history.
public enum HistoryLimit: Int, CaseIterable, Identifiable, Codable, Sendable {
    case twenty = 20
    case fifty = 50
    case hundred = 100
    case fiveHundred = 500
    case unlimited = 0

    public var id: Int { rawValue }

    public var title: String {
        switch self {
        case .twenty: return "20 screenshots"
        case .fifty: return "50 screenshots"
        case .hundred: return "100 screenshots"
        case .fiveHundred: return "500 screenshots"
        case .unlimited: return "Unlimited"
        }
    }
}

/// Age retention cutoff for history items.
public enum HistoryRetention: Int, CaseIterable, Identifiable, Codable, Sendable {
    case unlimited = 0
    case oneDay = 1
    case sevenDays = 7
    case thirtyDays = 30
    case ninetyDays = 90

    public var id: Int { rawValue }

    public var title: String {
        switch self {
        case .unlimited: return "Never"
        case .oneDay: return "1 day"
        case .sevenDays: return "7 days"
        case .thirtyDays: return "30 days"
        case .ninetyDays: return "90 days"
        }
    }
}
