# Story 03 - Persistent History Store and Retention

## Goal

Persist clipboard history locally and maintain a fast recent-history index with bounded retention.

## Why this matters

The picker must be fast, and history must survive restarts without unbounded disk growth.

## Scope

* Implement the `ClipboardHistoryItem` model and storage schema.
* Store metadata in SQLite or a structured local store.
* Store large payloads and thumbnails as local files when appropriate.
* Maintain an in-memory recent-items index.
* Apply default retention rules for item count and storage size.
* Prune old entries and associated blobs.

## Acceptance Criteria

* Captured history survives app restart.
* Recent items can be loaded quickly without scanning the full storage set each time.
* Default retention is applied with reasonable initial values from the spec.
* When retention limits are exceeded, the oldest items are pruned automatically.
* Pruning also removes associated thumbnail and payload files.
* Metadata writes are safe enough that a crash does not make the full store unreadable.
* The store remains local-only and does not depend on any network service.

## Dependencies

* Story 02

## Spec Coverage

* FR-8 through FR-11
* FR-22
* section 9
* section 15
* NFR-4
* NFR-6
* NFR-8
* NFR-9
