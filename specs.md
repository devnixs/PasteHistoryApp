# macOS Clipboard History App — Detailed Product & Technical Specification

## 1. Project Summary

Build a personal-use macOS utility app that records clipboard history and lets the user paste older clipboard items on demand.

The app should behave as follows:

* `⌘V` continues to work exactly as normal.
* `⌘⇧V` opens a history picker.
* The picker shows recent clipboard items, including image previews for image entries.
* Selecting an item restores it to the system clipboard and pastes it into the currently focused app.

This is a single-user desktop utility intended only for local personal use. It does not need cloud sync, account systems, licensing, telemetry, collaboration, or App Store distribution support.

---

## 2. Goals

### Primary goals

* Capture clipboard history automatically in the background.
* Preserve normal paste behavior for `⌘V`.
* Provide a fast keyboard-driven picker on `⌘⇧V`.
* Support both text and images.
* Paste a selected history item into the active application with minimal friction.
* Run unobtrusively as a menu bar app.

### Secondary goals

* Support rich text and file references where practical.
* Persist clipboard history across app restarts.
* Provide lightweight controls for pruning or clearing history.
* Handle privacy-sensitive data conservatively.

### Non-goals

* App Store release.
* iCloud sync or multi-device sync.
* Team sharing.
* Clipboard editing/transformation tools.
* OCR, AI features, translation, summarization.
* Browser extensions.
* Windows or Linux support.
* Full Paste.app feature parity.

---

## 3. Target User

Single technical user: the developer building the app.

Characteristics:

* Comfortable with desktop tooling and keyboard-driven workflows.
* Wants quick access to historical clipboard items.
* Needs reliable paste behavior across common macOS applications.
* Accepts a setup step for permissions if required.

---

## 4. Platform and Technology Decisions

## Platform

* macOS only

## Recommended implementation stack

* **Language:** Swift
* **UI:** SwiftUI
* **System integration:** AppKit
* **Persistence:** SQLite or structured local file storage
* **Image handling:** native AppKit/CoreGraphics APIs
* **Distribution target:** unsigned/local development build or locally signed Developer ID build for personal use

## Rationale

Swift + SwiftUI + AppKit is the most direct route to native macOS clipboard, menu bar, hotkey, window, and accessibility integration. The app’s critical functionality depends heavily on macOS-native APIs.

---

## 5. User Experience Overview

## 5.1 App mode

The app runs primarily as a **menu bar utility**. It may have no dock presence or a minimal settings window depending on implementation choice.

## 5.2 Main interaction flow

1. User copies content in any app.
2. Background monitor detects a clipboard change.
3. Clipboard item is normalized and stored in history.
4. User presses `⌘⇧V`.
5. History picker appears.
6. User navigates items with keyboard or mouse.
7. User selects an item.
8. App writes that item back to the clipboard.
9. App triggers paste into the previously active app.
10. Picker closes.

## 5.3 Standard paste behavior

* `⌘V` must remain unchanged.
* The app must not intercept, override, block, or remap normal paste.

---

## 6. Functional Requirements

# 6.1 Clipboard Monitoring

## FR-1: Monitor general clipboard

The app shall monitor the macOS general pasteboard continuously while running.

## FR-2: Detect changes

The app shall detect clipboard updates using pasteboard change tracking.

## FR-3: Capture supported content types

The app shall capture at minimum:

* plain text
* images

The app should also support, where feasible:

* rich text
* file URLs
* HTML
* multiple representations of the same clipboard item

## FR-4: Normalize captured items

Each clipboard event shall be converted into a normalized internal history record that includes:

* unique ID
* timestamp
* detected type
* display title/summary
* preview metadata
* raw stored payload or a reference to stored payload
* source app identifier if available

## FR-5: Deduplicate consecutive entries

The app shall avoid storing redundant consecutive duplicates.

## FR-6: Ignore unsupported/empty data

The app shall skip clipboard updates that do not contain a supported or storable representation.

## FR-7: Size-aware capture

The app shall enforce reasonable handling for large payloads, especially images, to avoid excessive memory and disk usage.

---

# 6.2 Clipboard History Storage

## FR-8: In-memory recent history

The app shall maintain a recent in-memory index for fast picker access.

## FR-9: Persistent history

The app shall persist clipboard history locally on disk so that entries survive application restart.

## FR-10: Configurable retention

The app should support configurable retention policies:

* max item count
* max total storage size
* optional time-based expiry

## FR-11: Pruning

The app shall automatically prune old entries when retention limits are exceeded.

## FR-12: Clear history

The user shall be able to clear all clipboard history manually.

---

# 6.3 Item Types and Rendering

## FR-13: Text item support

Text items shall display:

* a one-line or multi-line preview
* truncated content in list view
* full content in detail/expanded preview if implemented

## FR-14: Image item support

Image items shall display:

* image thumbnail in the history picker
* dimensions if practical
* fallback label such as “Image” when metadata is limited

## FR-15: Rich text fallback

For rich text, the app shall store the richest feasible representation and also maintain a plain-text fallback for preview/search.

## FR-16: File URL support

If file references are supported, the picker shall display:

* filename
* file type icon or generic icon
* path preview where helpful

## FR-17: Unknown item fallback

Unsupported or partially supported item types may be represented as generic items or omitted.

---

# 6.4 History Picker

## FR-18: Global shortcut

Pressing `⌘⇧V` shall open the clipboard history picker from anywhere in the system.

## FR-19: Picker appearance

The picker shall appear quickly and predictably, ideally as a floating transient window/panel.

## FR-20: Keyboard-first navigation

The picker shall support:

* up/down arrow navigation
* Enter/Return to confirm selection
* Escape to close
* optional search/filter typing

## FR-21: Mouse support

The picker shall also support mouse selection.

## FR-22: Item ordering

Items shall be listed newest first by default.

## FR-23: Search/filter

The picker should support filtering history items by typed query, at least for text-based items.

## FR-24: Selection state

The current selected item shall be visually highlighted.

## FR-25: Thumbnail rendering

Image entries shall display thumbnails inline in the picker.

## FR-26: Empty state

If there is no history, the picker shall show a clear empty state.

---

# 6.5 Paste Execution

## FR-27: Selection behavior

When the user selects a history item, the app shall:

1. restore the selected item to the system clipboard
2. trigger paste into the app that was focused before the picker opened

## FR-28: Preserve item fidelity

The restored clipboard item should preserve as much original type fidelity as practical.

## FR-29: Return focus to target app

After item selection, focus should return to the previously active application before paste is triggered.

## FR-30: Failure handling

If automatic paste cannot be performed, the app shall:

* restore the clipboard item
* notify the user or fail gracefully
* avoid destructive behavior

## FR-31: No normal paste interference

The app shall not change default behavior for `⌘V`.

---

# 6.6 Menu Bar App

## FR-32: Menu bar presence

The app shall run as a menu bar app with an icon.

## FR-33: Menu items

The menu bar menu shall include at minimum:

* open history picker
* settings/preferences
* clear history
* quit

## FR-34: Launch at login

The app should support launch at login.

---

# 6.7 Preferences

## FR-35: User-configurable settings

Preferences should include:

* max history count
* storage cap
* launch at login
* optional exclusion rules
* shortcut customization if implemented later

## FR-36: Privacy controls

Preferences should include:

* clear history
* optional auto-expire
* optional “pause clipboard capture”

## FR-37: Exclusions

The app should support excluding clipboard captures from specific source apps in a later phase.

---

## 7. Non-Functional Requirements

# 7.1 Performance

## NFR-1: Low idle overhead

Background clipboard monitoring shall consume minimal CPU while idle.

## NFR-2: Fast picker open

The picker should appear within approximately 100–200 ms under normal conditions.

## NFR-3: Fast navigation

Scrolling and keyboard navigation in recent history shall feel immediate.

## NFR-4: Bounded storage growth

History storage shall remain bounded by configured retention policies.

---

# 7.2 Reliability

## NFR-5: No clipboard corruption

The app must not corrupt or partially overwrite clipboard data during capture or restore.

## NFR-6: Safe recovery

If the app crashes or is force-quit, persisted history already written to disk should remain usable.

## NFR-7: Graceful degradation

If an item type cannot be fully restored, the app should fall back gracefully or refuse restoration rather than producing invalid clipboard content.

---

# 7.3 Privacy and Security

## NFR-8: Local-only data

Clipboard history shall be stored locally only.

## NFR-9: No telemetry

The app shall send no analytics or telemetry.

## NFR-10: Sensitive content risk acknowledgement

The app shall assume clipboard data may include secrets, passwords, private messages, tokens, and images.

## NFR-11: Sensitive content minimization

The app should provide mechanisms to reduce exposure:

* history clearing
* pause capture
* expiration
* optional app exclusions

## NFR-12: Permission transparency

Any required macOS permissions shall be clearly explained to the user.

---

# 7.4 Usability

## NFR-13: Keyboard-centric workflow

The primary workflow shall be usable without a mouse.

## NFR-14: Minimal friction

The app should require as few manual steps as possible after initial setup.

## NFR-15: Native behavior

The app should feel consistent with native macOS utility conventions.

---

## 8. Permissions and macOS Constraints

## 8.1 Clipboard access

The app requires access to the general system pasteboard.

Potential implications:

* macOS may present prompts or impose privacy behavior depending on access patterns and OS version.
* The app must handle pasteboard access failures gracefully.

## 8.2 Accessibility permission

If the app simulates `⌘V` or otherwise sends input events to another app, it will likely require Accessibility permission.

Requirement:

* The app shall detect whether required accessibility permission is granted.
* The app shall present a clear setup flow explaining why the permission is needed.
* The app shall degrade gracefully if permission is not granted.

## 8.3 Foreground application coordination

The app must handle activation/focus transfer carefully:

* remember frontmost app before opening picker
* reactivate it before paste
* avoid leaving focus stuck in the picker

---

## 9. Information Architecture / Data Model

## 9.1 ClipboardHistoryItem

Suggested model:

* `id: UUID`
* `createdAt: Date`
* `sourceAppBundleIdentifier: String?`
* `kind: ClipboardItemKind`
* `title: String`
* `subtitle: String?`
* `searchText: String?`
* `previewImagePath: String?`
* `payloadStoragePath: String?`
* `textPreview: String?`
* `imageWidth: Int?`
* `imageHeight: Int?`
* `utiTypes: [String]`
* `byteSize: Int64`
* `isPinned: Bool` (future)
* `isSensitive: Bool?` (future/manual)

## 9.2 ClipboardItemKind

Enum:

* `text`
* `richText`
* `image`
* `fileURL`
* `html`
* `unknown`

## 9.3 Storage layout

Possible local structure:

* SQLite DB for metadata
* filesystem blobs for large payloads and thumbnails

Example:

* `/Application Support/ClipboardApp/history.sqlite`
* `/Application Support/ClipboardApp/blobs/...`
* `/Application Support/ClipboardApp/thumbnails/...`

---

## 10. UI Specification

# 10.1 Menu Bar UI

## Menu contents

* Open Clipboard History
* Pause Capture / Resume Capture
* Clear History
* Preferences…
* Quit

Optional:

* Show current history count
* Recent items quick submenu

---

# 10.2 History Picker UI

## Layout

* Search field at top
* Scrollable list of history items
* Each row contains:

  * type icon or image thumbnail
  * title/preview
  * subtitle/metadata
  * timestamp or relative recency if desired

## Text item row

* First line: text preview
* Optional second line: copied time, source app, length

## Image item row

* Thumbnail on left
* Label such as `Image • 1280×720`
* Timestamp/source app secondary line

## Selection interaction

* Arrow keys move highlight
* Enter pastes selected item
* Escape closes
* Double-click pastes
* Search filters in real time

## Window behavior

* Non-resizable or lightly resizable
* Closes automatically after selection
* Closes on Escape or click outside if appropriate
* Opens centered or near cursor
* Should not permanently steal workflow focus

---

# 10.3 Preferences UI

Sections:

1. General
2. History
3. Privacy
4. Permissions

## General

* Launch at login
* Start hidden in menu bar
* Shortcut display

## History

* Max history items
* Max storage size
* Keep text items
* Keep image items
* Optional file item support

## Privacy

* Clear history
* Pause capture
* Auto-expire after X days
* Exclude apps (future)

## Permissions

* Accessibility status
* Clipboard-related status/help text
* “Open System Settings” helper action

---

## 11. Technical Architecture

## 11.1 Core components

### ClipboardMonitor

Responsibilities:

* poll or observe pasteboard change count
* detect meaningful changes
* read pasteboard representations
* pass captured data to normalization/storage

### ClipboardNormalizer

Responsibilities:

* inspect pasteboard item types
* determine best internal item kind
* create previews
* extract metadata
* generate fallback text when possible

### HistoryStore

Responsibilities:

* persist item metadata
* manage blob storage
* prune old items
* query recent/searchable items

### HotkeyManager

Responsibilities:

* register global `⌘⇧V`
* invoke picker open action
* handle registration failures

### PickerCoordinator

Responsibilities:

* capture currently frontmost app before showing picker
* open/close picker panel
* manage selection callbacks

### PasteService

Responsibilities:

* restore selected item to pasteboard
* reactivate prior frontmost app
* synthesize paste command if allowed
* report failures

### ThumbnailService

Responsibilities:

* generate and cache image thumbnails
* manage thumbnail cleanup

### PermissionsService

Responsibilities:

* detect accessibility trust state
* present user guidance
* open relevant system settings if needed

### SettingsStore

Responsibilities:

* manage user preferences
* expose retention and privacy settings

---

## 11.2 Suggested module boundaries

* `App`
* `UI`
* `Clipboard`
* `Storage`
* `Hotkeys`
* `Permissions`
* `Services`
* `Models`

This should remain a single-app codebase, not a multi-process architecture, unless later required.

---

## 12. Clipboard Capture Behavior Details

## 12.1 Polling strategy

Initial implementation may poll `NSPasteboard.general.changeCount` on a short interval.

Requirements:

* polling interval should balance responsiveness and CPU usage
* repeated unchanged values do nothing
* changed values trigger item read and normalization

## 12.2 Duplicate detection

At minimum, the app should avoid back-to-back duplicates based on:

* item kind
* payload fingerprint/hash where possible
* text equality for text
* image hash or byte hash for images if practical

## 12.3 Preview extraction

For text:

* trim leading/trailing whitespace for preview only
* preserve original content in payload

For images:

* generate downscaled thumbnail
* preserve original image representation if possible

---

## 13. Paste Flow Specification

## 13.1 Successful paste sequence

1. User invokes picker with `⌘⇧V`.
2. App stores reference to currently frontmost app.
3. Picker appears.
4. User selects item.
5. App writes selected item to `NSPasteboard.general`.
6. App closes picker.
7. App re-activates target app.
8. App sends synthetic `⌘V`.
9. Paste completes.

## 13.2 Failure modes

Possible failures:

* accessibility permission missing
* target app lost focus
* clipboard restore failed
* unsupported item restore
* picker cancelled

Required behavior:

* never crash
* never interfere with normal system paste
* provide minimal but clear feedback where helpful

## 13.3 Fallback mode

If automatic paste is unavailable:

* selected item shall still be restored to the clipboard
* user can manually press `⌘V`

Optional UX:

* small banner/toast: “Copied to clipboard. Press ⌘V to paste.”

---

## 14. History Search Specification

## Search scope

Search should initially apply only to:

* plain text content
* text previews of rich text items
* filenames/file URLs if supported

## Search behavior

* case-insensitive
* substring matching for MVP
* incremental filter as user types

## Search exclusions

Image-only entries without associated text need not be searchable in MVP beyond metadata labels.

---

## 15. Storage and Retention Rules

## Default recommended retention

* Max items: 100
* Max disk usage: 250 MB
* Images included: yes
* Auto-expire: off by default or 30 days, depending on privacy preference

## Pruning priority

When pruning is needed:

1. oldest unpinned entries first
2. large stale image entries first if size cap exceeded
3. associated thumbnails/blobs must also be deleted

## Persistence guarantees

* metadata writes should be atomic where possible
* blob files should not be orphaned after normal pruning
* on startup, integrity cleanup should remove orphaned thumbnails/blobs

---

## 16. Error Handling Requirements

## General

* All background failures must be logged.
* User-visible errors should be rare and concise.
* The app should recover automatically where possible.

## Cases to handle

* failed pasteboard read
* failed image decoding
* failed thumbnail generation
* failed hotkey registration
* inaccessible disk location
* insufficient permissions for synthetic paste

## Logging

For a personal tool, local logging is sufficient:

* console logs in debug
* optional file log in release/dev-use build

---

## 17. Accessibility and Keyboard Requirements

* All picker actions must be accessible from keyboard alone.
* Visible focus/selection state must be clear.
* Search field must autofocus when picker opens, unless arrow-first navigation is preferred by design.
* Keyboard shortcuts shown in UI must match actual configured bindings.

---

## 18. Privacy Specification

Even for a personal tool, this app handles high-risk private data.

## Required privacy controls

* clear all history
* pause capture
* bounded retention
* local-only storage

## Recommended future privacy controls

* ignore source apps such as password managers
* temporary “private mode”
* exclude copied items marked sensitive by source app if detectable
* auto-delete text that looks like passwords or OTPs only if explicitly enabled

Default stance:

* avoid clever heuristics in MVP
* give manual controls and clear expectations

---

## 19. MVP Definition

The MVP shall include:

* menu bar app
* clipboard monitoring
* support for:

  * plain text
  * images
* persistent local history
* global shortcut `⌘⇧V`
* picker with:

  * list view
  * keyboard navigation
  * image thumbnails
  * Enter to select
  * Escape to cancel
* restore selected item to clipboard
* attempt automatic paste into prior focused app
* basic settings:

  * max history size
  * clear history
  * launch at login
* permission guidance for accessibility

The MVP shall exclude:

* pinned items
* app exclusions
* advanced search
* rich text fidelity guarantees
* file URL previews beyond basic handling
* custom shortcut remapping
* advanced animations/polish

---

## 20. Post-MVP Enhancements

Priority order:

### Phase 2

* file URL support
* rich text support improvements
* search field
* source app display
* pause capture
* auto-expire

### Phase 3

* app exclusions
* pin/favorite items
* better preview panel
* custom hotkeys
* better duplicate collapsing
* accessibility polish

### Phase 4

* richer content inspection
* groups by date/app/type
* quick actions from menu bar
* import/export settings/history
* advanced sensitive-data controls

---

## 21. Acceptance Criteria

The project is successful when all of the following are true:

1. Copying text in any common macOS app causes it to appear in history.
2. Copying an image causes an image entry with thumbnail preview to appear in history.
3. Pressing `⌘V` behaves exactly as it did before the app was installed.
4. Pressing `⌘⇧V` opens the picker from any foreground app.
5. The picker can be navigated using arrow keys and Enter.
6. Selecting a history item restores it to the clipboard.
7. When permissions allow, selecting a history item pastes it into the previously focused app automatically.
8. When permissions do not allow automatic paste, the selected item still lands on the clipboard safely.
9. History persists across app restart.
10. The app runs unobtrusively from the menu bar and does not consume excessive resources.

---

## 22. Suggested Development Plan

## Milestone 1 — Project shell

* Create menu bar app
* Add preferences window
* Add basic history list model

## Milestone 2 — Clipboard capture

* Monitor pasteboard
* Capture plain text
* Persist entries
* Show entries in simple list

## Milestone 3 — Picker

* Floating picker window
* Keyboard navigation
* Selection callbacks

## Milestone 4 — Paste integration

* Capture frontmost app
* Restore clipboard item
* Re-focus target app
* Trigger synthetic paste
* Handle permission flow

## Milestone 5 — Images

* Capture image clipboard items
* Generate thumbnails
* Display in picker
* Add storage management

## Milestone 6 — Polish

* Deduplication
* Retention/pruning
* clear history
* launch at login
* error handling and logging

---

## 23. Open Technical Questions

These should be resolved early in implementation:

1. Which global hotkey mechanism will be used?
2. What exact picker window behavior feels best: centered, near cursor, or near insertion context?
3. How much representation fidelity should be preserved for rich text and images?
4. Should unsupported item types be skipped or shown generically?
5. What is the most reliable focus restoration sequence before synthetic paste?
6. What retention defaults feel safe enough for personal use?

---

## 24. Concise Engineering Recommendation

Build the first version as a **SwiftUI menu bar app with AppKit-based clipboard, hotkey, and paste integration**, targeting a narrow MVP: text + images, keyboard picker, restore-and-paste flow, local persistence, and explicit privacy controls.

That scope is small enough to finish, but complete enough to become a real daily-use tool.

I can turn this into a proper engineering spec document next, with sections like API contracts, class skeletons, user stories, and milestone tickets.
