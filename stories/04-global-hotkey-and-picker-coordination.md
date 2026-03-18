# Story 04 - Global Hotkey and Picker Coordination

## Goal

Open a transient clipboard history picker from anywhere in the system using `Command+Shift+V`.

## Why this matters

The product’s core interaction is a global picker that complements normal paste without replacing it.

## Scope

* Register a global hotkey for `Command+Shift+V`.
* Preserve normal `Command+V` behavior completely.
* Capture the frontmost app before presenting the picker.
* Present and dismiss a floating picker panel predictably.
* Handle hotkey registration failure gracefully.

## Acceptance Criteria

* Pressing `Command+Shift+V` opens the picker from other apps.
* Pressing `Command+V` behaves exactly as normal and is not intercepted.
* The picker opens as a transient floating window or panel.
* The currently focused application is recorded before the picker opens.
* The picker can be closed without side effects.
* If hotkey registration fails, the app logs the failure and exposes a graceful fallback path through the menu bar.

## Dependencies

* Story 01
* Story 03

## Spec Coverage

* FR-18
* FR-19
* FR-31
* section 5.2
* section 8.3
* `HotkeyManager`
* `PickerCoordinator`
