# Story 13 - Advanced Retention and Integrity Cleanup

## Goal

Strengthen long-term storage behavior with auto-expiry, smarter pruning, and startup cleanup.

## Why this matters

A clipboard database that runs for months needs stronger lifecycle management than simple count-based pruning.

## Scope

* Add optional time-based expiry.
* Improve pruning prioritization for large stale images and old unpinned entries.
* Run startup integrity cleanup for orphaned blobs and thumbnails.
* Add disk-location and write-failure recovery paths.

## Acceptance Criteria

* The user can optionally enable time-based expiry.
* Startup cleanup removes orphaned blobs and thumbnails created by prior abnormal termination or partial writes.
* Pruning remains bounded by count, disk size, and optional age.
* Pruning decisions are deterministic and logged for debugging.
* Storage corruption in one item does not make the rest of history unusable.

## Dependencies

* Story 03
* Story 08
* Story 09

## Spec Coverage

* FR-10
* FR-11
* section 15
* NFR-6
* section 20 phase 2 and phase 3
