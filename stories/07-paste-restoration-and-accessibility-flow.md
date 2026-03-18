# Story 07 - Paste Restoration and Accessibility Flow

## Goal

Restore a selected history item to the system clipboard, return focus to the previous app, and attempt automatic paste when permissions allow.

## Why this matters

This is the product payoff: selecting an older clipboard item should result in a paste with minimal friction.

## Scope

* Restore selected clipboard items to `NSPasteboard.general`.
* Reactivate the app that was focused before the picker opened.
* Attempt synthetic `Command+V` when accessibility access is available.
* Detect missing accessibility permission and guide the user.
* Fall back cleanly when automatic paste is not possible.

## Acceptance Criteria

* Selecting an item restores that item to the system clipboard.
* After selection, the picker closes and focus returns to the previously active app.
* When accessibility permission is granted, the app attempts a synthetic paste.
* When accessibility permission is missing, the item is still restored to the clipboard and the app does not crash.
* The user is given concise guidance on why accessibility permission is needed.
* Failures in restore, focus return, or synthetic paste are logged and handled gracefully.
* Normal `Command+V` behavior remains untouched.

## Dependencies

* Story 04
* Story 05
* Story 06

## Spec Coverage

* FR-27 through FR-31
* section 8.2
* section 13
* `PasteService`
* `PermissionsService`
* NFR-12
