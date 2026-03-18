# Story 09 - Privacy Controls and History Management

## Goal

Add the core privacy and manual-control features required for a clipboard tool that may store sensitive data.

## Why this matters

Clipboard history is high-risk by default. The MVP needs explicit controls to reduce exposure.

## Scope

* Add clear-history actions in the menu and preferences.
* Add pause and resume capture.
* Ensure local-only data handling is explicit in the app.
* Make failures around sensitive content handling conservative and non-destructive.

## Acceptance Criteria

* The user can clear all clipboard history from the menu bar.
* The user can clear all clipboard history from preferences.
* The user can pause clipboard capture and later resume it.
* While capture is paused, new clipboard changes are not added to history.
* Clearing history removes stored metadata, payloads, and thumbnails.
* The app exposes no telemetry or remote storage behavior.

## Dependencies

* Story 03
* Story 08

## Spec Coverage

* FR-12
* FR-36
* NFR-8 through NFR-11
* section 18
* section 19
