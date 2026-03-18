import AppKit
import ApplicationServices
import Combine
import Foundation

@MainActor
final class PermissionsService: ObservableObject {
    private let accessibilityPromptKey = "permissions.accessibilityPromptRequested"

    @Published private(set) var accessibilityStatus: AccessibilityStatus = .unknown

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
    }

    func openSystemSettings() {
        guard let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") else {
            return
        }

        NSWorkspace.shared.open(url)
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
