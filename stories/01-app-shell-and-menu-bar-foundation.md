# Story 01 - App Shell and Menu Bar Foundation

## Goal

Create the macOS app shell as a menu bar utility with the baseline structure needed for clipboard monitoring, picker presentation, settings, and quitting the app.

## Why this matters

The rest of the product depends on a stable native app lifecycle, menu bar presence, and clear module boundaries.

## Scope

* Create the Swift/SwiftUI macOS app target.
* Configure the app to run primarily as a menu bar app.
* Add a menu bar icon and menu.
* Add placeholder actions for opening history, opening preferences, clearing history, pausing capture, and quitting.
* Establish module boundaries for app, models, services, clipboard, storage, permissions, hotkeys, and UI.

## Acceptance Criteria

* The app launches successfully on macOS as a local development build.
* The app appears in the menu bar with a stable icon.
* The menu includes:
  * Open Clipboard History
  * Pause Capture / Resume Capture
  * Clear History
  * Preferences
  * Quit
* The app can operate without a normal dock-driven workflow, or uses the minimal dock presence chosen by the implementation.
* The codebase structure supports the components named in the spec:
  * `ClipboardMonitor`
  * `ClipboardNormalizer`
  * `HistoryStore`
  * `HotkeyManager`
  * `PickerCoordinator`
  * `PasteService`
  * `ThumbnailService`
  * `PermissionsService`
  * `SettingsStore`

## Dependencies

None.

## Spec Coverage

* FR-32
* FR-33
* section 10.1
* section 11
* section 19
