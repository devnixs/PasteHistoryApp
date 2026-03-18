import SwiftUI

@main
struct PasteHistoryApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var environment = AppEnvironment.shared

    var body: some Scene {
        MenuBarExtra {
            MenuBarMenuView()
                .environmentObject(environment)
        } label: {
            Label("Paste History", systemImage: "clipboard")
        }
        .menuBarExtraStyle(.menu)

        Settings {
            PreferencesView()
                .environmentObject(environment)
                .frame(width: 520, height: 420)
        }
    }
}
