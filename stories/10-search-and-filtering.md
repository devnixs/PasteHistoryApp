# Story 10 - Search and Filtering

## Goal

Allow the picker to filter history by typed query for supported text-based entries.

## Why this matters

Search is the main post-MVP improvement that makes larger history sets usable.

## Scope

* Add a search field to the picker.
* Autofocus the field on picker open if that is the selected interaction model.
* Filter items incrementally with case-insensitive substring matching.
* Search text content, text previews, and filenames when available.

## Acceptance Criteria

* The picker displays a search field.
* Typing filters results in real time.
* Search is case-insensitive.
* Text entries match against stored preview or search text.
* Image-only entries without text may remain unsearchable in MVP-plus behavior.
* Clearing the query restores the full recent-history list.

## Dependencies

* Story 05
* Story 11

## Spec Coverage

* FR-20 optional search/filter typing
* FR-23
* section 14
* section 17
* Phase 2
