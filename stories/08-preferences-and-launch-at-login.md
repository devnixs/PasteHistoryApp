# Story 08 - Preferences and Launch at Login

## Goal

Provide a preferences UI for the basic controls required by the MVP, including launch-at-login support.

## Why this matters

Users need control over retention and startup behavior without editing code or local files.

## Scope

* Build a preferences window.
* Implement settings storage for:
  * max history count
  * storage cap
  * launch at login
* Show permission status and helper actions.
* Surface the configured shortcut as display-only if customization is deferred.

## Acceptance Criteria

* A preferences window is accessible from the menu bar.
* The user can change max history count.
* The user can change the storage cap.
* The user can enable or disable launch at login.
* Preferences persist across restarts.
* The permissions section shows accessibility status with guidance or helper action.

## Dependencies

* Story 03
* Story 07

## Spec Coverage

* FR-34
* FR-35
* section 10.3
* section 19
* `SettingsStore`
