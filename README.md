# PasteHistoryApp

`PasteHistoryApp` is a native macOS menu bar clipboard history utility built with Swift, SwiftUI, and AppKit.

It records clipboard history in the background, shows a picker with `Command+Shift+V`, and can restore older clipboard items back to the system clipboard.

## Current feature set

* Menu bar app with no normal dock workflow
* Background clipboard monitoring
* Clipboard history persistence on disk
* Support for:
  * plain text
  * rich text
  * images
  * file URLs
* Global `Command+Shift+V` history picker
* Keyboard and mouse navigation in the picker
* Search/filter in the picker
* Image thumbnail caching
* Restore selected items to the clipboard
* Attempt automatic paste into the previously focused app
* Preferences for:
  * history size
  * storage cap
  * auto-expire
  * launch at login
  * privacy controls
  * exclusion rules

## Requirements

* macOS 14 or newer
* Xcode 26.3 or another Xcode version compatible with your installed macOS

Command Line Tools alone are not enough for this project. Use full Xcode.

## Project structure

* [Package.swift](/Users/raphael/Projects/MacOS/PasteHistoryApp/Package.swift): Swift package definition
* [Sources/](/Users/raphael/Projects/MacOS/PasteHistoryApp/Sources): app source
* [stories/](/Users/raphael/Projects/MacOS/PasteHistoryApp/stories): implementation stories derived from the product spec
* [scripts/package_app.sh](/Users/raphael/Projects/MacOS/PasteHistoryApp/scripts/package_app.sh): release packaging helper
* [Packaging/Info.plist](/Users/raphael/Projects/MacOS/PasteHistoryApp/Packaging/Info.plist): app bundle metadata for packaging

## Getting started

### 1. Install Xcode

Install Xcode from the Mac App Store or Apple Developer downloads.

Then run:

```bash
sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
sudo xcodebuild -runFirstLaunch
```

Check the active path:

```bash
xcode-select -p
```

Expected output:

```bash
/Applications/Xcode.app/Contents/Developer
```

### 2. Open the project

This repo is a Swift Package Manager project.

You can open it in Xcode by opening:

* [Package.swift](/Users/raphael/Projects/MacOS/PasteHistoryApp/Package.swift)

Or from Terminal:

```bash
open Package.swift
```

### 3. Build from Terminal

```bash
swift build
```

### 4. Run from Xcode

Open the package in Xcode, select the `PasteHistoryApp` target, and press Run.

## Permissions

### Accessibility

Automatic paste requires Accessibility permission.

Without that permission:

* the app can still restore the selected item to the clipboard
* you can paste manually with `Command+V`

### Clipboard access

Depending on your macOS version, the system may show privacy prompts related to clipboard access behavior.

## Packaging a distributable app

Build and package the app bundle with:

```bash
scripts/package_app.sh
```

This creates:

* `dist/PasteHistoryApp.app`
* `dist/PasteHistoryApp-macOS.zip`

## Installing on another Mac

Move the generated zip or `.app` to the other machine.

This project currently produces an ad-hoc signed local app bundle, not a notarized Developer ID release.

If macOS blocks launch on the other machine, use one of these options:

1. Right-click the app and choose `Open`
2. Remove quarantine from Terminal:

```bash
xattr -dr com.apple.quarantine /path/to/PasteHistoryApp.app
```

## Notes

* Clipboard history is stored locally on disk.
* The app sends no telemetry or analytics.
* Some system integration behavior may vary across macOS versions.

## Development notes

The app was built incrementally from the requirements in [specs.md](/Users/raphael/Projects/MacOS/PasteHistoryApp/specs.md), with the implementation backlog tracked in [stories/README.md](/Users/raphael/Projects/MacOS/PasteHistoryApp/stories/README.md).
