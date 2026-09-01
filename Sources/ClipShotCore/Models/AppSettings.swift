import Foundation
import SwiftUI
import Combine

/// Central observable model managing all user preferences for ClipShot.
/// Automatically persists to UserDefaults and synchronizes state across views.
public final class AppSettings: ObservableObject {
    public static let shared = AppSettings()

    private let defaults: UserDefaults
    private let managesSystemPreferences: Bool

    // MARK: - Keys
    private enum Keys {
        static let autoCopyEnabled = "autoCopyEnabled"
        static let instantPasteEnabled = "instantPasteEnabled"
        static let monitoringActive = "monitoringActive"
        static let showDockIcon = "showDockIcon"
        static let showMenuBarIcon = "showMenuBarIcon"
        static let playSoundOnCopy = "playSoundOnCopy"
        static let notifyOnError = "notifyOnError"
        static let autoCheckScreenshotFolder = "autoCheckScreenshotFolder"
        static let customScreenshotFolderPath = "customScreenshotFolderPath"
        static let screenshotFolderBookmark = "screenshotFolderBookmark"
        static let detectionMode = "detectionMode"
        static let clipboardOnlyMode = "clipboardOnlyMode"
        static let afterCopyAction = "afterCopyAction"
        static let deleteAfterDelaySeconds = "deleteAfterDelaySeconds"
        static let clipboardMode = "clipboardMode"
        static let preferPNG = "preferPNG"
        static let preserveTransparency = "preserveTransparency"
        static let preserveOriginalResolution = "preserveOriginalResolution"
        static let showFloatingPreview = "showFloatingPreview"
        static let previewDuration = "previewDuration"
        static let previewCorner = "previewCorner"
        static let pausePreviewOnHover = "pausePreviewOnHover"
        static let historyEnabled = "historyEnabled"
        static let historyLimit = "historyLimit"
        static let historyRetention = "historyRetention"
        static let storeDeletedScreenshotCopies = "storeDeletedScreenshotCopies"
        static let detectionSensitivity = "detectionSensitivity"
        static let ignoreImagesModifiedAfterCreation = "ignoreImagesModifiedAfterCreation"
        static let retryMetadataDetection = "retryMetadataDetection"
        static let hasCompletedOnboarding = "hasCompletedOnboarding"
        static let appearance = "appearance"
        static let defaultCaptureMode = "defaultCaptureMode"
        static let showMagnifier = "showMagnifier"
        static let showDimensions = "showDimensions"
        static let includeWindowShadow = "includeWindowShadow"
        static let freezeScreenOnCapture = "freezeScreenOnCapture"
        static let rememberLastArea = "rememberLastArea"
        static let lastSelectedArea = "lastSelectedArea"
        static let colorPickerFormat = "colorPickerFormat"
        static let recentColors = "recentColors"
        static let floatingToolStyle = "floatingToolStyle"
        static let floatingToolAutoCollapse = "floatingToolAutoCollapse"
        static let captureDelaySeconds = "captureDelaySeconds"
        static let recordingFPS = "recordingFPS"
        static let recordingFormat = "recordingFormat"
        static let recordMicrophone = "recordMicrophone"
        static let openEditorAutomatically = "openEditorAutomatically"
        static let clipNotchEnabled = "clipNotchEnabled"
        static let clipNotchDisplayUUID = "clipNotchDisplayUUID"
        static let clipNotchFallbackToMain = "clipNotchFallbackToMain"
        static let clipNotchPlacementMode = "clipNotchPlacementMode"
        static let clipNotchVerticalOffset = "clipNotchVerticalOffset"
        static let clipNotchIdleContent = "clipNotchIdleContent"
        static let clipNotchSize = "clipNotchSize"
        static let clipNotchAutoCollapseDuration = "clipNotchAutoCollapseDuration"
        static let clipNotchExpandOnHover = "clipNotchExpandOnHover"
        static let clipNotchVideoFPS = "clipNotchVideoFPS"
        static let clipNotchVideoSize = "clipNotchVideoSize"
        static let clipNotchOLEDProtection = "clipNotchOLEDProtection"
        static let clipNotchShowInFullscreen = "clipNotchShowInFullscreen"
        static let clipNotchColorway = "clipNotchColorway"
        static let clipNotchFinish = "clipNotchFinish"
        static let clipNotchMotion = "clipNotchMotion"
    }

    // MARK: - Published Properties

    @Published public var autoCopyEnabled: Bool {
        didSet { defaults.set(autoCopyEnabled, forKey: Keys.autoCopyEnabled) }
    }

    @Published public var instantPasteEnabled: Bool {
        didSet {
            defaults.set(instantPasteEnabled, forKey: Keys.instantPasteEnabled)
            applyInstantPastePreference()
        }
    }

    @Published public var monitoringActive: Bool {
        didSet { defaults.set(monitoringActive, forKey: Keys.monitoringActive) }
    }

    @Published public var showDockIcon: Bool {
        didSet {
            defaults.set(showDockIcon, forKey: Keys.showDockIcon)
            updateActivationPolicy()
        }
    }

    @Published public var showMenuBarIcon: Bool {
        didSet { defaults.set(showMenuBarIcon, forKey: Keys.showMenuBarIcon) }
    }

    @Published public var playSoundOnCopy: Bool {
        didSet { defaults.set(playSoundOnCopy, forKey: Keys.playSoundOnCopy) }
    }

    @Published public var notifyOnError: Bool {
        didSet { defaults.set(notifyOnError, forKey: Keys.notifyOnError) }
    }

    @Published public var autoCheckScreenshotFolder: Bool {
        didSet { defaults.set(autoCheckScreenshotFolder, forKey: Keys.autoCheckScreenshotFolder) }
    }

    @Published public var customScreenshotFolderPath: String? {
        didSet { defaults.set(customScreenshotFolderPath, forKey: Keys.customScreenshotFolderPath) }
    }

    @Published public var screenshotFolderBookmark: Data? {
        didSet { defaults.set(screenshotFolderBookmark, forKey: Keys.screenshotFolderBookmark) }
    }

    @Published public var detectionMode: DetectionMode {
        didSet { defaults.set(detectionMode.rawValue, forKey: Keys.detectionMode) }
    }

    @Published public var clipboardOnlyMode: Bool {
        didSet { defaults.set(clipboardOnlyMode, forKey: Keys.clipboardOnlyMode) }
    }

    @Published public var afterCopyAction: AfterCopyAction {
        didSet { defaults.set(afterCopyAction.rawValue, forKey: Keys.afterCopyAction) }
    }

    @Published public var deleteAfterDelaySeconds: Int {
        didSet { defaults.set(deleteAfterDelaySeconds, forKey: Keys.deleteAfterDelaySeconds) }
    }

    @Published public var clipboardMode: ClipboardMode {
        didSet { defaults.set(clipboardMode.rawValue, forKey: Keys.clipboardMode) }
    }

    @Published public var preferPNG: Bool {
        didSet { defaults.set(preferPNG, forKey: Keys.preferPNG) }
    }

    @Published public var preserveTransparency: Bool {
        didSet { defaults.set(preserveTransparency, forKey: Keys.preserveTransparency) }
    }

    @Published public var preserveOriginalResolution: Bool {
        didSet { defaults.set(preserveOriginalResolution, forKey: Keys.preserveOriginalResolution) }
    }

    @Published public var showFloatingPreview: Bool {
        didSet { defaults.set(showFloatingPreview, forKey: Keys.showFloatingPreview) }
    }

    @Published public var previewDuration: Double {
        didSet { defaults.set(previewDuration, forKey: Keys.previewDuration) }
    }

    @Published public var previewCorner: PreviewCorner {
        didSet { defaults.set(previewCorner.rawValue, forKey: Keys.previewCorner) }
    }

    @Published public var pausePreviewOnHover: Bool {
        didSet { defaults.set(pausePreviewOnHover, forKey: Keys.pausePreviewOnHover) }
    }

    @Published public var historyEnabled: Bool {
        didSet { defaults.set(historyEnabled, forKey: Keys.historyEnabled) }
    }

    @Published public var historyLimit: HistoryLimit {
        didSet { defaults.set(historyLimit.rawValue, forKey: Keys.historyLimit) }
    }

    @Published public var historyRetention: HistoryRetention {
        didSet { defaults.set(historyRetention.rawValue, forKey: Keys.historyRetention) }
    }

    @Published public var storeDeletedScreenshotCopies: Bool {
        didSet { defaults.set(storeDeletedScreenshotCopies, forKey: Keys.storeDeletedScreenshotCopies) }
    }

    @Published public var detectionSensitivity: DetectionSensitivity {
        didSet { defaults.set(detectionSensitivity.rawValue, forKey: Keys.detectionSensitivity) }
    }

    @Published public var ignoreImagesModifiedAfterCreation: Bool {
        didSet { defaults.set(ignoreImagesModifiedAfterCreation, forKey: Keys.ignoreImagesModifiedAfterCreation) }
    }

    @Published public var retryMetadataDetection: Bool {
        didSet { defaults.set(retryMetadataDetection, forKey: Keys.retryMetadataDetection) }
    }

    @Published public var hasCompletedOnboarding: Bool {
        didSet { defaults.set(hasCompletedOnboarding, forKey: Keys.hasCompletedOnboarding) }
    }

    @Published public var appearance: AppearanceSetting {
        didSet {
            defaults.set(appearance.rawValue, forKey: Keys.appearance)
            applyAppearance()
        }
    }

    @Published public var defaultCaptureMode: CaptureMode {
        didSet { defaults.set(defaultCaptureMode.rawValue, forKey: Keys.defaultCaptureMode) }
    }

    @Published public var showMagnifier: Bool {
        didSet { defaults.set(showMagnifier, forKey: Keys.showMagnifier) }
    }

    @Published public var showDimensions: Bool {
        didSet { defaults.set(showDimensions, forKey: Keys.showDimensions) }
    }

    @Published public var includeWindowShadow: Bool {
        didSet { defaults.set(includeWindowShadow, forKey: Keys.includeWindowShadow) }
    }

    @Published public var freezeScreenOnCapture: Bool {
        didSet { defaults.set(freezeScreenOnCapture, forKey: Keys.freezeScreenOnCapture) }
    }

    @Published public var rememberLastArea: Bool {
        didSet { defaults.set(rememberLastArea, forKey: Keys.rememberLastArea) }
    }

    @Published public var lastSelectedArea: CGRect? {
        didSet {
            if let rect = lastSelectedArea {
                defaults.set(NSStringFromRect(NSRectFromCGRect(rect)), forKey: Keys.lastSelectedArea)
            } else {
                defaults.removeObject(forKey: Keys.lastSelectedArea)
            }
        }
    }

    @Published public var colorPickerFormat: ColorFormat {
        didSet { defaults.set(colorPickerFormat.rawValue, forKey: Keys.colorPickerFormat) }
    }

    @Published public var recentColors: [String] {
        didSet { defaults.set(recentColors, forKey: Keys.recentColors) }
    }

    @Published public var floatingToolStyle: FloatingToolStyle {
        didSet { defaults.set(floatingToolStyle.rawValue, forKey: Keys.floatingToolStyle) }
    }

    @Published public var floatingToolAutoCollapse: Bool {
        didSet { defaults.set(floatingToolAutoCollapse, forKey: Keys.floatingToolAutoCollapse) }
    }

    @Published public var captureDelaySeconds: Int {
        didSet { defaults.set(captureDelaySeconds, forKey: Keys.captureDelaySeconds) }
    }

    @Published public var recordingFPS: Int {
        didSet { defaults.set(recordingFPS, forKey: Keys.recordingFPS) }
    }

    @Published public var recordingFormat: String {
        didSet { defaults.set(recordingFormat, forKey: Keys.recordingFormat) }
    }

    @Published public var recordMicrophone: Bool {
        didSet { defaults.set(recordMicrophone, forKey: Keys.recordMicrophone) }
    }

    @Published public var openEditorAutomatically: Bool {
        didSet { defaults.set(openEditorAutomatically, forKey: Keys.openEditorAutomatically) }
    }

    // MARK: - ClipNotch Properties

    @Published public var clipNotchEnabled: Bool {
        didSet { defaults.set(clipNotchEnabled, forKey: Keys.clipNotchEnabled) }
    }

    @Published public var clipNotchDisplayUUID: String? {
        didSet { defaults.set(clipNotchDisplayUUID, forKey: Keys.clipNotchDisplayUUID) }
    }

    @Published public var clipNotchFallbackToMain: Bool {
        didSet { defaults.set(clipNotchFallbackToMain, forKey: Keys.clipNotchFallbackToMain) }
    }

    @Published public var clipNotchPlacementMode: ClipNotchPlacementMode {
        didSet { defaults.set(clipNotchPlacementMode.rawValue, forKey: Keys.clipNotchPlacementMode) }
    }

    @Published public var clipNotchVerticalOffset: Double {
        didSet { defaults.set(clipNotchVerticalOffset, forKey: Keys.clipNotchVerticalOffset) }
    }

    @Published public var clipNotchIdleContent: ClipNotchIdleContent {
        didSet { defaults.set(clipNotchIdleContent.rawValue, forKey: Keys.clipNotchIdleContent) }
    }

    @Published public var clipNotchSize: ClipNotchSize {
        didSet { defaults.set(clipNotchSize.rawValue, forKey: Keys.clipNotchSize) }
    }

    @Published public var clipNotchAutoCollapseDuration: Double {
        didSet { defaults.set(clipNotchAutoCollapseDuration, forKey: Keys.clipNotchAutoCollapseDuration) }
    }

    @Published public var clipNotchExpandOnHover: Bool {
        didSet { defaults.set(clipNotchExpandOnHover, forKey: Keys.clipNotchExpandOnHover) }
    }

    @Published public var clipNotchVideoFPS: Int {
        didSet { defaults.set(clipNotchVideoFPS, forKey: Keys.clipNotchVideoFPS) }
    }

    @Published public var clipNotchVideoSize: VideoCapsuleSize {
        didSet { defaults.set(clipNotchVideoSize.rawValue, forKey: Keys.clipNotchVideoSize) }
    }

    @Published public var clipNotchOLEDProtection: Bool {
        didSet { defaults.set(clipNotchOLEDProtection, forKey: Keys.clipNotchOLEDProtection) }
    }

    @Published public var clipNotchShowInFullscreen: Bool {
        didSet { defaults.set(clipNotchShowInFullscreen, forKey: Keys.clipNotchShowInFullscreen) }
    }

    @Published public var clipNotchColorway: ClipNotchColorway {
        didSet { defaults.set(clipNotchColorway.rawValue, forKey: Keys.clipNotchColorway) }
    }

    @Published public var clipNotchFinish: ClipNotchFinish {
        didSet { defaults.set(clipNotchFinish.rawValue, forKey: Keys.clipNotchFinish) }
    }

    @Published public var clipNotchMotion: ClipNotchMotion {
        didSet { defaults.set(clipNotchMotion.rawValue, forKey: Keys.clipNotchMotion) }
    }

    // MARK: - Init

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.managesSystemPreferences = defaults === UserDefaults.standard

        defaults.register(defaults: [
            Keys.autoCopyEnabled: true,
            Keys.instantPasteEnabled: true,
            Keys.monitoringActive: true,
            Keys.showDockIcon: false,
            Keys.showMenuBarIcon: true,
            Keys.playSoundOnCopy: false,
            Keys.notifyOnError: true,
            Keys.autoCheckScreenshotFolder: true,
            Keys.detectionMode: DetectionMode.screenshotsOnly.rawValue,
            Keys.clipboardOnlyMode: false,
            Keys.afterCopyAction: AfterCopyAction.keep.rawValue,
            Keys.deleteAfterDelaySeconds: 5,
            Keys.clipboardMode: ClipboardMode.imageOnly.rawValue,
            Keys.preferPNG: true,
            Keys.preserveTransparency: true,
            Keys.preserveOriginalResolution: true,
            Keys.showFloatingPreview: true,
            Keys.previewDuration: 5.0,
            Keys.previewCorner: PreviewCorner.bottomRight.rawValue,
            Keys.pausePreviewOnHover: true,
            Keys.historyEnabled: true,
            Keys.historyLimit: HistoryLimit.hundred.rawValue,
            Keys.historyRetention: HistoryRetention.thirtyDays.rawValue,
            Keys.storeDeletedScreenshotCopies: false,
            Keys.detectionSensitivity: DetectionSensitivity.balanced.rawValue,
            Keys.ignoreImagesModifiedAfterCreation: true,
            Keys.retryMetadataDetection: true,
            Keys.hasCompletedOnboarding: false,
            Keys.appearance: AppearanceSetting.system.rawValue,
            Keys.defaultCaptureMode: CaptureMode.area.rawValue,
            Keys.showMagnifier: true,
            Keys.showDimensions: true,
            Keys.includeWindowShadow: true,
            Keys.freezeScreenOnCapture: true,
            Keys.rememberLastArea: true,
            Keys.colorPickerFormat: ColorFormat.hex.rawValue,
            Keys.recentColors: ["#007AFF", "#34C759", "#FF9500", "#FF3B30", "#AF52DE", "#000000", "#FFFFFF"],
            Keys.floatingToolStyle: FloatingToolStyle.hidden.rawValue,
            Keys.floatingToolAutoCollapse: true,
            Keys.captureDelaySeconds: 0,
            Keys.recordingFPS: 60,
            Keys.recordingFormat: "MP4",
            Keys.recordMicrophone: false,
            Keys.openEditorAutomatically: false,
            Keys.clipNotchEnabled: true,
            Keys.clipNotchFallbackToMain: true,
            Keys.clipNotchPlacementMode: ClipNotchPlacementMode.topHeader.rawValue,
            Keys.clipNotchVerticalOffset: 0.0,
            Keys.clipNotchIdleContent: ClipNotchIdleContent.minimalIcon.rawValue,
            Keys.clipNotchSize: ClipNotchSize.normal.rawValue,
            Keys.clipNotchAutoCollapseDuration: 4.5,
            Keys.clipNotchExpandOnHover: true,
            Keys.clipNotchVideoFPS: 30,
            Keys.clipNotchVideoSize: VideoCapsuleSize.medium.rawValue,
            Keys.clipNotchOLEDProtection: false,
            Keys.clipNotchShowInFullscreen: true,
            Keys.clipNotchColorway: ClipNotchColorway.prism.rawValue,
            Keys.clipNotchFinish: ClipNotchFinish.obsidian.rawValue,
            Keys.clipNotchMotion: ClipNotchMotion.fluid.rawValue
        ])

        self.autoCopyEnabled = defaults.bool(forKey: Keys.autoCopyEnabled)
        self.instantPasteEnabled = defaults.bool(forKey: Keys.instantPasteEnabled)
        self.monitoringActive = defaults.bool(forKey: Keys.monitoringActive)
        self.showDockIcon = defaults.bool(forKey: Keys.showDockIcon)
        self.showMenuBarIcon = defaults.bool(forKey: Keys.showMenuBarIcon)
        self.playSoundOnCopy = defaults.bool(forKey: Keys.playSoundOnCopy)
        self.notifyOnError = defaults.bool(forKey: Keys.notifyOnError)
        self.autoCheckScreenshotFolder = defaults.bool(forKey: Keys.autoCheckScreenshotFolder)
        self.customScreenshotFolderPath = defaults.string(forKey: Keys.customScreenshotFolderPath)
        self.screenshotFolderBookmark = defaults.data(forKey: Keys.screenshotFolderBookmark)

        let detModeRaw = defaults.string(forKey: Keys.detectionMode) ?? DetectionMode.screenshotsOnly.rawValue
        self.detectionMode = DetectionMode(rawValue: detModeRaw) ?? .screenshotsOnly

        self.clipboardOnlyMode = defaults.bool(forKey: Keys.clipboardOnlyMode)

        let afterCopyRaw = defaults.string(forKey: Keys.afterCopyAction) ?? AfterCopyAction.keep.rawValue
        self.afterCopyAction = AfterCopyAction(rawValue: afterCopyRaw) ?? .keep

        let delayVal = defaults.integer(forKey: Keys.deleteAfterDelaySeconds)
        self.deleteAfterDelaySeconds = delayVal == 0 ? 5 : delayVal

        let clipModeRaw = defaults.string(forKey: Keys.clipboardMode) ?? ClipboardMode.imageOnly.rawValue
        self.clipboardMode = ClipboardMode(rawValue: clipModeRaw) ?? .imageOnly

        self.preferPNG = defaults.bool(forKey: Keys.preferPNG)
        self.preserveTransparency = defaults.bool(forKey: Keys.preserveTransparency)
        self.preserveOriginalResolution = defaults.bool(forKey: Keys.preserveOriginalResolution)
        self.showFloatingPreview = defaults.bool(forKey: Keys.showFloatingPreview)

        let duration = defaults.double(forKey: Keys.previewDuration)
        self.previewDuration = duration > 0 ? duration : 5.0

        let cornerRaw = defaults.string(forKey: Keys.previewCorner) ?? PreviewCorner.bottomRight.rawValue
        self.previewCorner = PreviewCorner(rawValue: cornerRaw) ?? .bottomRight

        self.pausePreviewOnHover = defaults.bool(forKey: Keys.pausePreviewOnHover)
        self.historyEnabled = defaults.bool(forKey: Keys.historyEnabled)

        let limitRaw = defaults.integer(forKey: Keys.historyLimit)
        self.historyLimit = HistoryLimit(rawValue: limitRaw) ?? .hundred

        let retRaw = defaults.integer(forKey: Keys.historyRetention)
        self.historyRetention = HistoryRetention(rawValue: retRaw) ?? .thirtyDays

        self.storeDeletedScreenshotCopies = defaults.bool(forKey: Keys.storeDeletedScreenshotCopies)

        let sensRaw = defaults.string(forKey: Keys.detectionSensitivity) ?? DetectionSensitivity.balanced.rawValue
        self.detectionSensitivity = DetectionSensitivity(rawValue: sensRaw) ?? .balanced

        self.ignoreImagesModifiedAfterCreation = defaults.bool(forKey: Keys.ignoreImagesModifiedAfterCreation)
        self.retryMetadataDetection = defaults.bool(forKey: Keys.retryMetadataDetection)
        self.hasCompletedOnboarding = defaults.bool(forKey: Keys.hasCompletedOnboarding)

        let appRaw = defaults.string(forKey: Keys.appearance) ?? AppearanceSetting.system.rawValue
        self.appearance = AppearanceSetting(rawValue: appRaw) ?? .system

        let capModeRaw = defaults.string(forKey: Keys.defaultCaptureMode) ?? CaptureMode.area.rawValue
        self.defaultCaptureMode = CaptureMode(rawValue: capModeRaw) ?? .area

        self.showMagnifier = defaults.bool(forKey: Keys.showMagnifier)
        self.showDimensions = defaults.bool(forKey: Keys.showDimensions)
        self.includeWindowShadow = defaults.bool(forKey: Keys.includeWindowShadow)
        self.freezeScreenOnCapture = defaults.bool(forKey: Keys.freezeScreenOnCapture)
        self.rememberLastArea = defaults.bool(forKey: Keys.rememberLastArea)

        if let rectStr = defaults.string(forKey: Keys.lastSelectedArea) {
            self.lastSelectedArea = NSRectToCGRect(NSRectFromString(rectStr))
        } else {
            self.lastSelectedArea = nil
        }

        let colorFmtRaw = defaults.string(forKey: Keys.colorPickerFormat) ?? ColorFormat.hex.rawValue
        self.colorPickerFormat = ColorFormat(rawValue: colorFmtRaw) ?? .hex

        self.recentColors = defaults.stringArray(forKey: Keys.recentColors) ?? ["#007AFF", "#34C759", "#FF9500", "#FF3B30", "#AF52DE", "#000000", "#FFFFFF"]

        let floatStyleRaw = defaults.string(forKey: Keys.floatingToolStyle) ?? FloatingToolStyle.hidden.rawValue
        self.floatingToolStyle = FloatingToolStyle(rawValue: floatStyleRaw) ?? .hidden

        self.floatingToolAutoCollapse = defaults.bool(forKey: Keys.floatingToolAutoCollapse)
        self.captureDelaySeconds = defaults.integer(forKey: Keys.captureDelaySeconds)

        let fps = defaults.integer(forKey: Keys.recordingFPS)
        self.recordingFPS = fps > 0 ? fps : 60

        self.recordingFormat = defaults.string(forKey: Keys.recordingFormat) ?? "MP4"
        self.recordMicrophone = defaults.bool(forKey: Keys.recordMicrophone)
        self.openEditorAutomatically = defaults.bool(forKey: Keys.openEditorAutomatically)

        self.clipNotchEnabled = defaults.bool(forKey: Keys.clipNotchEnabled)
        self.clipNotchDisplayUUID = defaults.string(forKey: Keys.clipNotchDisplayUUID)
        self.clipNotchFallbackToMain = defaults.bool(forKey: Keys.clipNotchFallbackToMain)

        let notchPlaceRaw = defaults.string(forKey: Keys.clipNotchPlacementMode) ?? ClipNotchPlacementMode.topHeader.rawValue
        self.clipNotchPlacementMode = ClipNotchPlacementMode(rawValue: notchPlaceRaw) ?? .topHeader

        self.clipNotchVerticalOffset = defaults.double(forKey: Keys.clipNotchVerticalOffset)

        let idleContentRaw = defaults.string(forKey: Keys.clipNotchIdleContent) ?? ClipNotchIdleContent.minimalIcon.rawValue
        self.clipNotchIdleContent = ClipNotchIdleContent(rawValue: idleContentRaw) ?? .minimalIcon

        let notchSizeRaw = defaults.string(forKey: Keys.clipNotchSize) ?? ClipNotchSize.normal.rawValue
        self.clipNotchSize = ClipNotchSize(rawValue: notchSizeRaw) ?? .normal

        let autoCollapse = defaults.double(forKey: Keys.clipNotchAutoCollapseDuration)
        self.clipNotchAutoCollapseDuration = autoCollapse > 0 ? autoCollapse : 4.5

        self.clipNotchExpandOnHover = defaults.bool(forKey: Keys.clipNotchExpandOnHover)

        let vFPS = defaults.integer(forKey: Keys.clipNotchVideoFPS)
        self.clipNotchVideoFPS = vFPS > 0 ? vFPS : 30

        let vSizeRaw = defaults.string(forKey: Keys.clipNotchVideoSize) ?? VideoCapsuleSize.medium.rawValue
        self.clipNotchVideoSize = VideoCapsuleSize(rawValue: vSizeRaw) ?? .medium

        self.clipNotchOLEDProtection = defaults.bool(forKey: Keys.clipNotchOLEDProtection)
        self.clipNotchShowInFullscreen = defaults.bool(forKey: Keys.clipNotchShowInFullscreen)

        let colorwayRaw = defaults.string(forKey: Keys.clipNotchColorway) ?? ClipNotchColorway.prism.rawValue
        self.clipNotchColorway = ClipNotchColorway(rawValue: colorwayRaw) ?? .prism

        let finishRaw = defaults.string(forKey: Keys.clipNotchFinish) ?? ClipNotchFinish.obsidian.rawValue
        self.clipNotchFinish = ClipNotchFinish(rawValue: finishRaw) ?? .obsidian

        let motionRaw = defaults.string(forKey: Keys.clipNotchMotion) ?? ClipNotchMotion.fluid.rawValue
        self.clipNotchMotion = ClipNotchMotion(rawValue: motionRaw) ?? .fluid

        applyInstantPastePreference()
        applyAppearance()
    }

    public func addRecentColor(_ colorHex: String) {
        var colors = recentColors
        colors.removeAll { $0.caseInsensitiveCompare(colorHex) == .orderedSame }
        colors.insert(colorHex, at: 0)
        if colors.count > 20 { colors = Array(colors.prefix(20)) }
        self.recentColors = colors
    }

    public func resetToDefaults() {
        autoCopyEnabled = true
        instantPasteEnabled = true
        monitoringActive = true
        showDockIcon = false
        showMenuBarIcon = true
        playSoundOnCopy = false
        notifyOnError = true
        autoCheckScreenshotFolder = true
        customScreenshotFolderPath = nil
        screenshotFolderBookmark = nil
        detectionMode = .screenshotsOnly
        clipboardOnlyMode = false
        afterCopyAction = .keep
        deleteAfterDelaySeconds = 5
        clipboardMode = .imageOnly
        preferPNG = true
        preserveTransparency = true
        preserveOriginalResolution = true
        showFloatingPreview = true
        previewDuration = 5.0
        previewCorner = .bottomRight
        pausePreviewOnHover = true
        historyEnabled = true
        historyLimit = .hundred
        historyRetention = .thirtyDays
        storeDeletedScreenshotCopies = false
        detectionSensitivity = .balanced
        ignoreImagesModifiedAfterCreation = true
        retryMetadataDetection = true
        appearance = .system
        defaultCaptureMode = .area
        showMagnifier = true
        showDimensions = true
        includeWindowShadow = true
        freezeScreenOnCapture = true
        rememberLastArea = true
        lastSelectedArea = nil
        colorPickerFormat = .hex
        recentColors = ["#007AFF", "#34C759", "#FF9500", "#FF3B30", "#AF52DE", "#000000", "#FFFFFF"]
        floatingToolStyle = .hidden
        floatingToolAutoCollapse = true
        captureDelaySeconds = 0
        recordingFPS = 60
        recordingFormat = "MP4"
        recordMicrophone = false
        openEditorAutomatically = false
        clipNotchEnabled = true
        clipNotchDisplayUUID = nil
        clipNotchFallbackToMain = true
        clipNotchPlacementMode = .topHeader
        clipNotchVerticalOffset = 0.0
        clipNotchIdleContent = .minimalIcon
        clipNotchSize = .normal
        clipNotchAutoCollapseDuration = 4.5
        clipNotchExpandOnHover = true
        clipNotchVideoFPS = 30
        clipNotchVideoSize = .medium
        clipNotchOLEDProtection = false
        clipNotchShowInFullscreen = true
        clipNotchColorway = .prism
        clipNotchFinish = .obsidian
        clipNotchMotion = .fluid
    }

    private func updateActivationPolicy() {
        #if os(macOS)
        DispatchQueue.main.async {
            if self.showDockIcon {
                NSApp?.setActivationPolicy(.regular)
            } else {
                NSApp?.setActivationPolicy(.accessory)
            }
        }
        #endif
    }

    private func applyInstantPastePreference() {
        guard managesSystemPreferences else { return }
        let domain = "com.apple.screencapture" as CFString
        CFPreferencesSetAppValue(
            "show-thumbnail" as CFString,
            instantPasteEnabled ? kCFBooleanFalse : kCFBooleanTrue,
            domain
        )
        CFPreferencesAppSynchronize(domain)
    }

    public func applyAppearance() {
        #if os(macOS)
        DispatchQueue.main.async {
            switch self.appearance {
            case .system:
                NSApp?.appearance = nil
            case .light:
                NSApp?.appearance = NSAppearance(named: .aqua)
            case .dark:
                NSApp?.appearance = NSAppearance(named: .darkAqua)
            }
        }
        #endif
    }
}
