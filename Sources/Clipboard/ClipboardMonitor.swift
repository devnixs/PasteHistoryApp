import AppKit
import Combine
import Foundation

@MainActor
final class ClipboardMonitor: ObservableObject {
    private static let pollingInterval: TimeInterval = 0.75

    private let normalizer: ClipboardNormalizer
    private let historyStore: HistoryStore
    private let settingsStore: SettingsStore
    private let pasteboard: NSPasteboard
    private var timer: Timer?
    private var lastObservedChangeCount: Int

    init(
        normalizer: ClipboardNormalizer,
        historyStore: HistoryStore,
        settingsStore: SettingsStore,
        pasteboard: NSPasteboard = .general
    ) {
        self.normalizer = normalizer
        self.historyStore = historyStore
        self.settingsStore = settingsStore
        self.pasteboard = pasteboard
        self.lastObservedChangeCount = pasteboard.changeCount
    }

    func start() {
        guard timer == nil else {
            return
        }

        lastObservedChangeCount = pasteboard.changeCount
        timer = Timer.scheduledTimer(withTimeInterval: Self.pollingInterval, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.pollPasteboard()
            }
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    var isPaused: Bool {
        settingsStore.isCapturePaused
    }

    private func pollPasteboard() {
        guard settingsStore.isCapturePaused == false else {
            lastObservedChangeCount = pasteboard.changeCount
            return
        }

        let currentChangeCount = pasteboard.changeCount
        guard currentChangeCount != lastObservedChangeCount else {
            return
        }

        lastObservedChangeCount = currentChangeCount

        let sourceAppIdentifier = NSWorkspace.shared.frontmostApplication?.bundleIdentifier
        guard settingsStore.isExcluded(bundleIdentifier: sourceAppIdentifier) == false else {
            return
        }

        guard let normalizedItem = normalizer.normalizeCurrentContents(
            of: pasteboard,
            sourceAppBundleIdentifier: sourceAppIdentifier
        ) else {
            return
        }

        historyStore.capture(normalizedItem)
    }
}
