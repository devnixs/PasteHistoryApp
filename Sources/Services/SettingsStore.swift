import Combine
import Foundation

@MainActor
final class SettingsStore: ObservableObject {
    private enum Key {
        static let isCapturePaused = "settings.isCapturePaused"
        static let maxHistoryItems = "settings.maxHistoryItems"
        static let storageCapMB = "settings.storageCapMB"
        static let autoExpireDays = "settings.autoExpireDays"
        static let launchAtLogin = "settings.launchAtLogin"
        static let excludedBundleIdentifiers = "settings.excludedBundleIdentifiers"
    }

    private let userDefaults: UserDefaults
    private let launchAtLoginService: LaunchAtLoginService
    private var isUpdatingLaunchAtLoginState = false

    @Published var isCapturePaused = false {
        didSet { persistBool(isCapturePaused, forKey: Key.isCapturePaused) }
    }

    @Published var maxHistoryItems = 100 {
        didSet { persistInt(maxHistoryItems, forKey: Key.maxHistoryItems) }
    }

    @Published var storageCapMB = 250 {
        didSet { persistInt(storageCapMB, forKey: Key.storageCapMB) }
    }

    @Published var autoExpireDays = 0 {
        didSet { persistInt(autoExpireDays, forKey: Key.autoExpireDays) }
    }

    @Published var launchAtLogin = false {
        didSet {
            persistBool(launchAtLogin, forKey: Key.launchAtLogin)
            guard isUpdatingLaunchAtLoginState == false else {
                return
            }
            syncLaunchAtLogin()
        }
    }

    @Published private(set) var excludedBundleIdentifiers: [String] = [] {
        didSet {
            userDefaults.set(excludedBundleIdentifiers, forKey: Key.excludedBundleIdentifiers)
        }
    }

    @Published private(set) var launchAtLoginStatusMessage: String?
    @Published private(set) var privacyStatusMessage = "Clipboard history is stored only on this Mac. The app sends no telemetry or analytics."

    init(
        userDefaults: UserDefaults = .standard,
        launchAtLoginService: LaunchAtLoginService = LaunchAtLoginService()
    ) {
        self.userDefaults = userDefaults
        self.launchAtLoginService = launchAtLoginService

        isCapturePaused = userDefaults.object(forKey: Key.isCapturePaused) as? Bool ?? false
        maxHistoryItems = userDefaults.object(forKey: Key.maxHistoryItems) as? Int ?? 100
        storageCapMB = userDefaults.object(forKey: Key.storageCapMB) as? Int ?? 250
        autoExpireDays = userDefaults.object(forKey: Key.autoExpireDays) as? Int ?? 0

        let savedLaunchSetting = userDefaults.object(forKey: Key.launchAtLogin) as? Bool
        let systemLaunchSetting = launchAtLoginService.currentValue()
        launchAtLogin = savedLaunchSetting ?? systemLaunchSetting
        excludedBundleIdentifiers = (userDefaults.array(forKey: Key.excludedBundleIdentifiers) as? [String] ?? [])
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { $0.isEmpty == false }
            .sorted()
        launchAtLoginStatusMessage = nil
    }

    func refreshLaunchAtLoginState() {
        isUpdatingLaunchAtLoginState = true
        launchAtLogin = launchAtLoginService.currentValue()
        isUpdatingLaunchAtLoginState = false
        launchAtLoginStatusMessage = nil
    }

    private func syncLaunchAtLogin() {
        do {
            try launchAtLoginService.setEnabled(launchAtLogin)
            launchAtLoginStatusMessage = nil
        } catch {
            launchAtLoginStatusMessage = error.localizedDescription
            NSLog("Launch-at-login update failed: \(error.localizedDescription)")
        }
    }

    private func persistBool(_ value: Bool, forKey key: String) {
        userDefaults.set(value, forKey: key)
    }

    private func persistInt(_ value: Int, forKey key: String) {
        userDefaults.set(value, forKey: key)
    }

    var captureStatusLabel: String {
        isCapturePaused ? "Capture Paused" : "Capture Active"
    }

    var autoExpireEnabled: Bool {
        autoExpireDays > 0
    }

    func addExcludedBundleIdentifier(_ bundleIdentifier: String) {
        let normalized = bundleIdentifier.trimmingCharacters(in: .whitespacesAndNewlines)
        guard normalized.isEmpty == false else {
            return
        }

        guard excludedBundleIdentifiers.contains(normalized) == false else {
            return
        }

        excludedBundleIdentifiers = (excludedBundleIdentifiers + [normalized]).sorted()
    }

    func removeExcludedBundleIdentifier(_ bundleIdentifier: String) {
        excludedBundleIdentifiers.removeAll { $0 == bundleIdentifier }
    }

    func isExcluded(bundleIdentifier: String?) -> Bool {
        guard let bundleIdentifier else {
            return false
        }

        return excludedBundleIdentifiers.contains(bundleIdentifier)
    }
}
