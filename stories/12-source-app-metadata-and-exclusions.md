# Story 12 - Source App Metadata and Exclusions

## Goal

Track where clipboard items came from and allow future exclusion of specific apps from capture.

## Why this matters

Source-app awareness supports debugging, trust, and later privacy controls for sensitive apps.

## Scope

* Improve source app detection during capture.
* Surface source app metadata in picker rows where useful.
* Add settings support for app exclusion rules.
* Prevent history capture for excluded bundle identifiers.

## Acceptance Criteria

* Source app bundle identifiers are captured when the app can obtain them reliably.
* Picker rows can show source app metadata without cluttering primary previews.
* The user can configure excluded apps.
* Clipboard changes originating from excluded apps are not stored.
* Exclusion failures default to conservative behavior and do not break capture for non-excluded apps.

## Dependencies

* Story 08
* Story 09

## Spec Coverage

* FR-4 source app identifier
* FR-35 optional exclusion rules
* FR-37
* section 18 recommended future privacy controls
* section 20 phase 3
