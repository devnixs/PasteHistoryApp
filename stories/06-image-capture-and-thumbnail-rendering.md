# Story 06 - Image Capture and Thumbnail Rendering

## Goal

Store image clipboard entries safely and generate thumbnails for fast picker display.

## Why this matters

Image support is part of the MVP and requires its own payload, preview, and storage behavior.

## Scope

* Preserve original image data where practical.
* Extract image dimensions where available.
* Generate downscaled thumbnails for picker display.
* Cache thumbnails locally.
* Handle failed image decoding or thumbnail generation gracefully.

## Acceptance Criteria

* Copied images are stored as history entries with the `image` kind.
* Image entries expose width and height metadata when available.
* Picker rows display generated thumbnails instead of decoding full-size images on every render.
* Thumbnail generation does not block the picker enough to feel broken.
* If thumbnail generation fails, the item still appears with a fallback label.
* Storage cleanup removes thumbnails associated with deleted entries.

## Dependencies

* Story 02
* Story 03
* Story 05

## Spec Coverage

* FR-14
* FR-25
* section 12.3
* `ThumbnailService`
* NFR-7
