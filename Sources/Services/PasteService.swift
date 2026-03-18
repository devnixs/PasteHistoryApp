import AppKit
import Carbon
import Combine
import Foundation

@MainActor
final class PasteService: ObservableObject {
    @Published private(set) var lastFeedbackMessage: String?

    private let historyStore: HistoryStore
    private let permissionsService: PermissionsService
    private let pickerCoordinator: PickerCoordinator

    init(
        historyStore: HistoryStore,
        permissionsService: PermissionsService,
        pickerCoordinator: PickerCoordinator
    ) {
        self.historyStore = historyStore
        self.permissionsService = permissionsService
        self.pickerCoordinator = pickerCoordinator
    }

    func pasteSelectedItem(_ item: ClipboardHistoryItem) {
        clearFeedback()
        do {
            try restoreClipboard(for: item)
        } catch {
            setFeedback("Could not restore that clipboard item.")
            NSLog("PasteService restore failed: \(error.localizedDescription)")
            return
        }

        let didReactivateTarget = pickerCoordinator.reactivatePreviousApplication()
        permissionsService.refreshAccessibilityStatus()

        guard permissionsService.accessibilityStatus == .granted else {
            setFeedback("Copied to clipboard. Press Command+V to paste.")
            return
        }

        guard didReactivateTarget else {
            setFeedback("Copied to clipboard. Return to the previous app and press Command+V.")
            return
        }

        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(120))
            if synthesizePasteCommand() {
                clearFeedback()
            } else {
                setFeedback("Copied to clipboard. Automatic paste failed, so press Command+V.")
            }
        }
    }

    func clearFeedback() {
        lastFeedbackMessage = nil
    }

    private func restoreClipboard(for item: ClipboardHistoryItem) throws {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()

        switch item.kind {
        case .text:
            try restorePlainText(item, on: pasteboard)
        case .richText:
            try restoreRichText(item, on: pasteboard)
        case .image:
            guard let payloadData = try payloadData(for: item) else {
                throw PasteError.unreadablePayload
            }

            pasteboard.declareTypes([.png], owner: nil)
            guard pasteboard.setData(payloadData, forType: .png) else {
                throw PasteError.restoreFailed
            }
        case .fileURL:
            try restoreFileURLs(item, on: pasteboard)
        default:
            throw PasteError.unsupportedItemType
        }
    }

    private func restorePlainText(_ item: ClipboardHistoryItem, on pasteboard: NSPasteboard) throws {
        guard
            let payloadData = try payloadData(for: item),
            let string = String(data: payloadData, encoding: .utf8)
        else {
            throw PasteError.unreadablePayload
        }

        guard pasteboard.setString(string, forType: .string) else {
            throw PasteError.restoreFailed
        }
    }

    private func restoreRichText(_ item: ClipboardHistoryItem, on pasteboard: NSPasteboard) throws {
        guard let payloadData = try payloadData(for: item) else {
            throw PasteError.unreadablePayload
        }

        pasteboard.declareTypes([.rtf, .string], owner: nil)
        guard pasteboard.setData(payloadData, forType: .rtf) else {
            throw PasteError.restoreFailed
        }

        if
            let attributedString = NSAttributedString(rtf: payloadData, documentAttributes: nil),
            attributedString.string.isEmpty == false
        {
            _ = pasteboard.setString(attributedString.string, forType: .string)
        }
    }

    private func restoreFileURLs(_ item: ClipboardHistoryItem, on pasteboard: NSPasteboard) throws {
        guard let payloadData = try payloadData(for: item) else {
            throw PasteError.unreadablePayload
        }

        let decoder = JSONDecoder()
        let rawURLs = try decoder.decode([String].self, from: payloadData)
        let urls = rawURLs.compactMap(URL.init(string:))
        guard urls.isEmpty == false else {
            throw PasteError.unreadablePayload
        }

        guard pasteboard.writeObjects(urls as [NSURL]) else {
            throw PasteError.restoreFailed
        }
    }

    private func payloadData(for item: ClipboardHistoryItem) throws -> Data? {
        guard let fileURL = historyStore.fileURL(forRelativePath: item.payloadStoragePath) else {
            return nil
        }

        return try Data(contentsOf: fileURL)
    }

    private func synthesizePasteCommand() -> Bool {
        guard
            let keyDown = CGEvent(keyboardEventSource: nil, virtualKey: CGKeyCode(kVK_ANSI_V), keyDown: true),
            let keyUp = CGEvent(keyboardEventSource: nil, virtualKey: CGKeyCode(kVK_ANSI_V), keyDown: false)
        else {
            NSLog("PasteService could not create synthetic paste events.")
            return false
        }

        keyDown.flags = .maskCommand
        keyUp.flags = .maskCommand
        keyDown.post(tap: .cghidEventTap)
        keyUp.post(tap: .cghidEventTap)
        return true
    }

    private func setFeedback(_ message: String) {
        lastFeedbackMessage = message
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(4))
            if self.lastFeedbackMessage == message {
                self.lastFeedbackMessage = nil
            }
        }
    }
}

private enum PasteError: Error {
    case unreadablePayload
    case restoreFailed
    case unsupportedItemType
}
