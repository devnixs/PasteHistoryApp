# Story 02 - Clipboard Monitoring and Normalization

## Goal

Detect clipboard changes in the background and convert supported clipboard content into normalized history records.

## Why this matters

Clipboard capture is the core product behavior. Without reliable monitoring and normalization, nothing else is useful.

## Scope

* Monitor `NSPasteboard.general.changeCount` on a low-overhead interval.
* Read supported clipboard content after each meaningful change.
* Support initial MVP types:
  * plain text
  * images
* Skip empty or unsupported clipboard states.
* Produce a normalized internal record with metadata suitable for storage and UI display.
* Deduplicate consecutive clipboard entries.

## Acceptance Criteria

* The app detects clipboard changes while running in the background.
* Unchanged poll cycles do not trigger storage work.
* Plain text clipboard content is captured into a normalized model.
* Image clipboard content is captured into a normalized model.
* Each normalized item includes:
  * unique ID
  * timestamp
  * item kind
  * title or preview summary
  * search or preview text where applicable
  * payload reference or inline payload metadata
  * source app identifier if available
* Back-to-back duplicate clipboard entries are not stored twice.
* Unsupported or empty clipboard contents are ignored safely.
* Large payload handling is bounded enough to avoid obvious memory spikes during capture.

## Dependencies

* Story 01

## Spec Coverage

* FR-1 through FR-7
* section 12
* NFR-1
* NFR-5
