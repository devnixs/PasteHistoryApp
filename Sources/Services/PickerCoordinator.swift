import AppKit
import Combine
import SwiftUI

@MainActor
final class PickerCoordinator: NSObject, ObservableObject, NSWindowDelegate {
    @Published private(set) var isHistoryPresented = false
    @Published private(set) var lastFocusedAppBundleIdentifier: String?

    private var panel: NSPanel?
    private var contentProvider: (() -> AnyView)?
    private var previouslyFocusedApplication: NSRunningApplication?
    private var suppressFocusRestoration = false

    func setContentProvider(_ provider: @escaping () -> AnyView) {
        contentProvider = provider
        updatePanelContentIfNeeded()
    }

    func openHistory() {
        previouslyFocusedApplication = currentFrontmostApplication()
        lastFocusedAppBundleIdentifier = previouslyFocusedApplication?.bundleIdentifier

        let panel = ensurePanel()
        NSApp.activate(ignoringOtherApps: true)
        panel.center()
        panel.makeKeyAndOrderFront(nil)
        isHistoryPresented = true
    }

    func closeHistory(restoreFocus: Bool = true) {
        panel?.orderOut(nil)
        isHistoryPresented = false
        guard restoreFocus else {
            return
        }

        _ = reactivatePreviousApplication()
    }

    func toggleHistory() {
        if isHistoryPresented {
            closeHistory()
        } else {
            openHistory()
        }
    }

    func reactivatePreviousApplication() -> Bool {
        guard let previouslyFocusedApplication else {
            return false
        }

        let didActivate = previouslyFocusedApplication.activate(options: [.activateIgnoringOtherApps])
        if didActivate {
            lastFocusedAppBundleIdentifier = previouslyFocusedApplication.bundleIdentifier
        }
        return didActivate
    }

    func prepareForPasteHandoff() {
        suppressFocusRestoration = true
    }

    func windowWillClose(_ notification: Notification) {
        isHistoryPresented = false
    }

    func windowDidResignKey(_ notification: Notification) {
        guard suppressFocusRestoration == false else {
            suppressFocusRestoration = false
            return
        }

        closeHistory()
    }

    private func ensurePanel() -> NSPanel {
        if let panel {
            updatePanelContentIfNeeded()
            return panel
        }

        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 560, height: 420),
            styleMask: [.titled, .closable, .fullSizeContentView, .utilityWindow],
            backing: .buffered,
            defer: false
        )
        panel.delegate = self
        panel.isFloatingPanel = true
        panel.level = .floating
        panel.collectionBehavior = [.moveToActiveSpace, .transient]
        panel.hidesOnDeactivate = true
        panel.titleVisibility = .hidden
        panel.titlebarAppearsTransparent = true
        panel.isReleasedWhenClosed = false
        panel.isMovableByWindowBackground = true
        panel.standardWindowButton(.zoomButton)?.isHidden = true
        panel.standardWindowButton(.miniaturizeButton)?.isHidden = true

        self.panel = panel
        updatePanelContentIfNeeded()
        return panel
    }

    private func updatePanelContentIfNeeded() {
        guard let panel, let contentProvider else {
            return
        }

        panel.contentViewController = NSHostingController(rootView: contentProvider())
    }

    private func currentFrontmostApplication() -> NSRunningApplication? {
        let application = NSWorkspace.shared.frontmostApplication
        guard application?.bundleIdentifier != Bundle.main.bundleIdentifier else {
            return previouslyFocusedApplication
        }

        return application
    }
}
