import SwiftUI

struct PreferencesView: View {
    @EnvironmentObject private var environment: AppEnvironment
    @State private var newExcludedBundleIdentifier = ""

    var body: some View {
        Form {
            Section("General") {
                Toggle("Launch at login", isOn: launchAtLoginBinding)

                if let launchAtLoginStatusMessage = environment.settingsStore.launchAtLoginStatusMessage {
                    Text(launchAtLoginStatusMessage)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                LabeledContent("Shortcut") {
                    Text(environment.hotkeyManager.shortcutDisplay)
                        .font(.body.monospaced())
                }
            }

            Section("History") {
                Stepper(value: maxHistoryItemsBinding, in: 1...1000) {
                    LabeledContent("Max history items") {
                        Text("\(environment.settingsStore.maxHistoryItems)")
                    }
                }

                Stepper(value: storageCapBinding, in: 10...2048, step: 10) {
                    LabeledContent("Storage cap (MB)") {
                        Text("\(environment.settingsStore.storageCapMB)")
                    }
                }

                Stepper(value: autoExpireDaysBinding, in: 0...365) {
                    LabeledContent("Auto-expire (days)") {
                        Text(environment.settingsStore.autoExpireEnabled ? "\(environment.settingsStore.autoExpireDays)" : "Off")
                    }
                }

                LabeledContent("Stored items") {
                    Text("\(environment.historyStore.itemCount)")
                }

                LabeledContent("Disk usage") {
                    Text(environment.historyStore.totalStorageDescription)
                }
            }

            Section("Privacy") {
                Toggle("Pause clipboard capture", isOn: capturePausedBinding)

                Text(environment.settingsStore.isCapturePaused
                    ? "Clipboard changes are ignored while capture is paused."
                    : "Clipboard monitoring is active. New supported copies are stored locally in history.")
                    .foregroundStyle(.secondary)

                Button("Clear History") {
                    environment.historyStore.clearHistory()
                }

                Text(environment.settingsStore.privacyStatusMessage)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("Exclusions") {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        TextField("Bundle identifier", text: $newExcludedBundleIdentifier)
                            .textFieldStyle(.roundedBorder)

                        Button("Add") {
                            environment.settingsStore.addExcludedBundleIdentifier(newExcludedBundleIdentifier)
                            newExcludedBundleIdentifier = ""
                        }
                        .disabled(newExcludedBundleIdentifier.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }

                    Button("Add Frontmost App") {
                        if let bundleIdentifier = NSWorkspace.shared.frontmostApplication?.bundleIdentifier {
                            environment.settingsStore.addExcludedBundleIdentifier(bundleIdentifier)
                        }
                    }

                    if environment.settingsStore.excludedBundleIdentifiers.isEmpty {
                        Text("No excluded apps. Clipboard capture runs for all source apps.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(environment.settingsStore.excludedBundleIdentifiers, id: \.self) { bundleIdentifier in
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(bundleIdentifier)
                                        .font(.body.monospaced())

                                    Text("Clipboard changes from this app will not be stored.")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }

                                Spacer()

                                Button("Remove") {
                                    environment.settingsStore.removeExcludedBundleIdentifier(bundleIdentifier)
                                }
                            }
                        }
                    }
                }
            }

            Section("Permissions") {
                LabeledContent("Accessibility") {
                    Text(environment.permissionsService.accessibilityStatus.displayName)
                }

                Text(environment.permissionsService.accessibilityStatus.guidanceText)
                    .foregroundStyle(.secondary)

                Text(environment.permissionsService.troubleshootingText)
                    .font(.caption.monospaced())
                    .foregroundStyle(.secondary)
                    .textSelection(.enabled)

                HStack {
                    if environment.permissionsService.accessibilityStatus == .notRequested {
                        Button("Request Access") {
                            environment.permissionsService.requestAccessibilityPermission()
                        }
                    }

                    Button("Open System Settings") {
                        environment.permissionsService.openSystemSettings()
                    }
                }
            }
        }
        .formStyle(.grouped)
        .padding(20)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .onAppear {
            environment.permissionsService.refreshAccessibilityStatus()
            environment.settingsStore.refreshLaunchAtLoginState()
        }
        .onChange(of: environment.settingsStore.maxHistoryItems) { _, _ in
            environment.historyStore.reapplyRetentionPolicies()
        }
        .onChange(of: environment.settingsStore.storageCapMB) { _, _ in
            environment.historyStore.reapplyRetentionPolicies()
        }
        .onChange(of: environment.settingsStore.autoExpireDays) { _, _ in
            environment.historyStore.reapplyRetentionPolicies()
        }
    }

    private var launchAtLoginBinding: Binding<Bool> {
        Binding(
            get: { environment.settingsStore.launchAtLogin },
            set: { environment.settingsStore.launchAtLogin = $0 }
        )
    }

    private var maxHistoryItemsBinding: Binding<Int> {
        Binding(
            get: { environment.settingsStore.maxHistoryItems },
            set: { environment.settingsStore.maxHistoryItems = $0 }
        )
    }

    private var storageCapBinding: Binding<Int> {
        Binding(
            get: { environment.settingsStore.storageCapMB },
            set: { environment.settingsStore.storageCapMB = $0 }
        )
    }

    private var autoExpireDaysBinding: Binding<Int> {
        Binding(
            get: { environment.settingsStore.autoExpireDays },
            set: { environment.settingsStore.autoExpireDays = $0 }
        )
    }

    private var capturePausedBinding: Binding<Bool> {
        Binding(
            get: { environment.settingsStore.isCapturePaused },
            set: { environment.settingsStore.isCapturePaused = $0 }
        )
    }
}
