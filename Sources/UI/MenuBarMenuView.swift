import AppKit
import SwiftUI

struct MenuBarMenuView: View {
    @EnvironmentObject private var environment: AppEnvironment

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                Text(environment.settingsStore.captureStatusLabel)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(environment.settingsStore.isCapturePaused ? .orange : .secondary)
                Text("\(environment.historyStore.itemCount) items • \(environment.historyStore.totalStorageDescription)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Divider()

            Button("Open Clipboard History") {
                environment.pickerCoordinator.openHistory()
            }

            Button(environment.settingsStore.isCapturePaused ? "Resume Capture" : "Pause Capture") {
                environment.settingsStore.isCapturePaused.toggle()
            }

            Button("Clear History") {
                environment.historyStore.clearHistory()
            }

            if let message = environment.hotkeyManager.registrationErrorMessage {
                Divider()

                Text(message)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Divider()

            SettingsLink {
                Text("Preferences…")
            }

            Divider()

            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
            .keyboardShortcut("q")
        }
        .padding(12)
        .frame(width: 260)
    }
}
