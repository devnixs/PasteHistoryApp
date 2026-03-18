import AppKit
import ApplicationServices
import Combine
import Foundation

@MainActor
final class PermissionsService: ObservableObject {
    private let accessibilityPromptKey = "permissions.accessibilityPromptRequested"
    private var accessibilityRefreshTask: Task<Void, Never>?
    private var didBecomeActiveObserver: Any?

    @Published private(set) var accessibilityStatus: AccessibilityStatus = .unknown

    init(notificationCenter: NotificationCenter = .default) {
        didBecomeActiveObserver = notificationCenter.addObserver(
            forName: NSApplication.didBecomeActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.refreshAccessibilityStatus()
            }
        }
    }

    func refreshAccessibilityStatus() {
        let isTrusted = AXIsProcessTrusted()

        if isTrusted {
            accessibilityStatus = .granted
            return
        }

        let hasPromptedBefore = UserDefaults.standard.bool(forKey: accessibilityPromptKey)
        accessibilityStatus = hasPromptedBefore ? .denied : .notRequested
    }

    func requestAccessibilityPermission() {
        let options = ["AXTrustedCheckOptionPrompt": true] as CFDictionary
        UserDefaults.standard.set(true, forKey: accessibilityPromptKey)
        _ = AXIsProcessTrustedWithOptions(options)
        refreshAccessibilityStatus()
        scheduleAccessibilityRefreshPolling()
    }

    func openSystemSettings() {
        guard let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") else {
            return
        }

        NSWorkspace.shared.open(url)
        scheduleAccessibilityRefreshPolling()
    }

    var bundleIdentifier: String {
        Bundle.main.bundleIdentifier ?? "Unavailable"
    }

    var appLocationPath: String {
        Bundle.main.bundleURL.path
    }

    var executablePath: String {
        Bundle.main.executablePath ?? ProcessInfo.processInfo.arguments.first ?? "Unavailable"
    }

    var troubleshootingText: String {
        """
        macOS grants Accessibility access to a specific app installation. If System Settings shows an older build as enabled, this running app can still be denied.
        Current app: \(bundleIdentifier)
        App path: \(appLocationPath)
        Executable: \(executablePath)
        If this still shows Denied, remove any old PasteHistoryApp entry in System Settings, then grant access again to the app at the path above.
        """
    }

    private func scheduleAccessibilityRefreshPolling() {
        accessibilityRefreshTask?.cancel()
        accessibilityRefreshTask = Task { @MainActor [weak self] in
            guard let self else {
                return
            }

            for delay in [0.5, 1.5, 3.0, 6.0, 10.0] {
                try? await Task.sleep(for: .seconds(delay))
                if Task.isCancelled {
                    return
                }

                self.refreshAccessibilityStatus()
                if self.accessibilityStatus == .granted {
                    return
                }
            }
        }
    }
}

enum AccessibilityStatus: String {
    case unknown
    case notRequested
    case denied
    case granted

    var displayName: String {
        switch self {
        case .unknown:
            return "Unknown"
        case .notRequested:
            return "Not Requested"
        case .denied:
            return "Denied"
        case .granted:
            return "Granted"
        }
    }

    var guidanceText: String {
        switch self {
        case .unknown:
            return "Accessibility status has not been checked yet."
        case .notRequested:
            return "Automatic paste needs Accessibility access. Without it, selected items are copied and you paste manually."
        case .denied:
            return "Accessibility access is off. Enable it in System Settings to allow automatic paste."
        case .granted:
            return "Accessibility access is enabled for automatic paste."
        }
    }
}
