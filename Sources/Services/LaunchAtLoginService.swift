import Foundation
import ServiceManagement

@MainActor
final class LaunchAtLoginService {
    func currentValue() -> Bool {
        if #available(macOS 13.0, *) {
            return SMAppService.mainApp.status == .enabled
        }

        return false
    }

    func setEnabled(_ isEnabled: Bool) throws {
        guard #available(macOS 13.0, *) else {
            throw LaunchAtLoginError.unsupportedSystem
        }

        if isEnabled {
            try SMAppService.mainApp.register()
        } else {
            try SMAppService.mainApp.unregister()
        }
    }
}

enum LaunchAtLoginError: LocalizedError {
    case unsupportedSystem

    var errorDescription: String? {
        switch self {
        case .unsupportedSystem:
            return "Launch at login requires macOS 13 or newer."
        }
    }
}
