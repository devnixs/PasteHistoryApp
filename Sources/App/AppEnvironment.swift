import Combine
import Foundation
import SwiftUI

@MainActor
final class AppEnvironment: ObservableObject {
    static let shared = AppEnvironment()

    let clipboardMonitor: ClipboardMonitor
    let clipboardNormalizer: ClipboardNormalizer
    let historyStore: HistoryStore
    let hotkeyManager: HotkeyManager
    let pickerCoordinator: PickerCoordinator
    let pasteService: PasteService
    let thumbnailService: ThumbnailService
    let permissionsService: PermissionsService
    let settingsStore: SettingsStore

    init() {
        let settingsStore = SettingsStore()
        let thumbnailService = ThumbnailService()
        let historyStore = HistoryStore(settingsStore: settingsStore, thumbnailService: thumbnailService)
        let clipboardNormalizer = ClipboardNormalizer()
        let permissionsService = PermissionsService()
        let pickerCoordinator = PickerCoordinator()
        let pasteService = PasteService(
            historyStore: historyStore,
            permissionsService: permissionsService,
            pickerCoordinator: pickerCoordinator
        )
        let clipboardMonitor = ClipboardMonitor(
            normalizer: clipboardNormalizer,
            historyStore: historyStore,
            settingsStore: settingsStore
        )
        let hotkeyManager = HotkeyManager()

        self.settingsStore = settingsStore
        self.historyStore = historyStore
        self.clipboardNormalizer = clipboardNormalizer
        self.permissionsService = permissionsService
        self.pickerCoordinator = pickerCoordinator
        self.pasteService = pasteService
        self.thumbnailService = thumbnailService
        self.clipboardMonitor = clipboardMonitor
        self.hotkeyManager = hotkeyManager

        pickerCoordinator.setContentProvider {
            AnyView(
                HistoryPickerView()
                    .environmentObject(AppEnvironment.shared)
            )
        }
        hotkeyManager.setAction { [weak pickerCoordinator] in
            pickerCoordinator?.openHistory()
        }
        permissionsService.refreshAccessibilityStatus()
        settingsStore.refreshLaunchAtLoginState()
        hotkeyManager.registerDefaultShortcut()
        clipboardMonitor.start()
    }
}
