# Story 05 - Picker List UI and Keyboard Navigation

## Goal

Render recent clipboard history in a picker UI that is fast, keyboard-first, and usable with text and image entries.

## Why this matters

Even with good capture and storage, the app fails if the picker feels slow, unclear, or mouse-dependent.

## Scope

* Build the picker list view in SwiftUI.
* Show items newest first.
* Render text previews and image rows with thumbnail support hooks.
* Support selection highlighting.
* Support keyboard navigation with arrow keys, Enter, and Escape.
* Support mouse selection and double-click.
* Provide an empty state when history is empty.

## Acceptance Criteria

* The picker lists recent items in descending recency order.
* The selected row is visually clear.
* Up and down arrows move selection.
* Enter confirms the selected item.
* Escape closes the picker.
* Mouse click selects an item.
* Double-click confirms an item.
* Text items show a readable truncated preview.
* Image items show a thumbnail area and metadata label.
* An empty-state message is shown when there is no history.
* Picker open and navigation are subjectively immediate under normal local history size.

## Dependencies

* Story 03
* Story 04

## Spec Coverage

* FR-20 through FR-26
* FR-13
* FR-14
* section 10.2
* NFR-2
* NFR-3
* NFR-13
* NFR-15
