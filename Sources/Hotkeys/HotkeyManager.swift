import Carbon
import Combine
import Foundation

private let hotKeySignature = OSType(0x50485354)
private let hotKeyIdentifier: UInt32 = 1

private let hotKeyEventHandler: EventHandlerUPP = { _, event, userData in
    guard
        let userData,
        let event,
        matchesRegisteredHotKey(event)
    else {
        return OSStatus(eventNotHandledErr)
    }

    let manager = Unmanaged<HotkeyManager>.fromOpaque(userData).takeUnretainedValue()
    Task { @MainActor in
        manager.triggerAction()
    }
    return noErr
}

@MainActor
final class HotkeyManager: ObservableObject {
    @Published private(set) var shortcutDisplay = "Command+Shift+V"
    @Published private(set) var isRegistered = false
    @Published private(set) var registrationErrorMessage: String?

    private var eventHotKey: EventHotKeyRef?
    private var eventHandler: EventHandlerRef?
    private let hotKeyID = EventHotKeyID(signature: hotKeySignature, id: hotKeyIdentifier)
    private var action: (() -> Void)?

    func setAction(_ action: @escaping () -> Void) {
        self.action = action
    }

    func registerDefaultShortcut() {
        unregister()

        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        let userData = UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())

        let handlerStatus = InstallEventHandler(
            GetApplicationEventTarget(),
            hotKeyEventHandler,
            1,
            &eventType,
            userData,
            &eventHandler
        )

        guard handlerStatus == noErr else {
            isRegistered = false
            registrationErrorMessage = "Failed to install the global hotkey handler."
            NSLog("Hotkey registration failed during handler install: \(handlerStatus)")
            return
        }

        let hotKeyID = self.hotKeyID
        let status = RegisterEventHotKey(
            UInt32(kVK_ANSI_V),
            UInt32(cmdKey | shiftKey),
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &eventHotKey
        )

        if status == noErr {
            isRegistered = true
            registrationErrorMessage = nil
        } else {
            isRegistered = false
            registrationErrorMessage = "Global shortcut registration failed. Use the menu bar item to open history."
            NSLog("Hotkey registration failed: \(status)")
        }
    }

    private func unregister() {
        if let eventHotKey {
            UnregisterEventHotKey(eventHotKey)
            self.eventHotKey = nil
        }

        if let eventHandler {
            RemoveEventHandler(eventHandler)
            self.eventHandler = nil
        }
    }

    fileprivate func triggerAction() {
        action?()
    }

}

private func matchesRegisteredHotKey(_ event: EventRef) -> Bool {
    var hotKeyID = EventHotKeyID()
    let status = GetEventParameter(
        event,
        EventParamName(kEventParamDirectObject),
        EventParamType(typeEventHotKeyID),
        nil,
        MemoryLayout<EventHotKeyID>.size,
        nil,
        &hotKeyID
    )

    guard status == noErr else {
        return false
    }

    return hotKeyID.signature == hotKeySignature && hotKeyID.id == hotKeyIdentifier
}
