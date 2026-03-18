# Story 11 - Rich Text and File URL Support

## Goal

Expand the capture and restore pipeline beyond plain text and images to support richer clipboard content.

## Why this matters

Rich text and file references improve fidelity for real workflows and reduce unexpected downgrades.

## Scope

* Capture rich text where feasible.
* Preserve a plain-text fallback for preview and search.
* Capture file URLs if present on the pasteboard.
* Render filename and lightweight metadata in the picker.
* Restore the richest safe representation available during paste.

## Acceptance Criteria

* Rich text items can be captured and stored with a plain-text preview.
* File URL items can be captured and shown with filename-focused display text.
* The picker can distinguish text, image, rich text, and file URL entries.
* Restore attempts prefer the richest stored representation that the app supports safely.
* Unsupported variants degrade gracefully instead of producing invalid clipboard states.

## Dependencies

* Story 02
* Story 03
* Story 05
* Story 07

## Spec Coverage

* FR-3 optional types
* FR-15
* FR-16
* FR-28
* section 20 phase 2
