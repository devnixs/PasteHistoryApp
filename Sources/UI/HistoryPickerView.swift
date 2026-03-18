import AppKit
import SwiftUI

struct HistoryPickerView: View {
    @EnvironmentObject private var environment: AppEnvironment
    @Environment(\.openSettings) private var openSettings
    @State private var selectedItemID: ClipboardHistoryItem.ID?
    @State private var searchQuery = ""
    @FocusState private var isSearchFieldFocused: Bool

    private var items: [ClipboardHistoryItem] {
        environment.historyStore.items
    }

    private var filteredItems: [ClipboardHistoryItem] {
        let trimmedQuery = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmedQuery.isEmpty == false else {
            return items
        }

        let normalizedQuery = trimmedQuery.localizedLowercase
        return items.filter { item in
            searchableText(for: item).localizedLowercase.contains(normalizedQuery)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            searchField

            if items.isEmpty {
                emptyState
            } else if filteredItems.isEmpty {
                noResultsState
            } else {
                pickerList
            }

            footer

            if let feedbackMessage = environment.pasteService.lastFeedbackMessage {
                Text(feedbackMessage)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if environment.permissionsService.accessibilityStatus != .granted {
                permissionHint
            }
        }
        .padding(16)
        .frame(minWidth: 520, minHeight: 460)
        .focusable()
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Clipboard history picker")
        .onAppear {
            environment.permissionsService.refreshAccessibilityStatus()
            resetSelectionIfNeeded()
            isSearchFieldFocused = true
        }
        .onChange(of: items.map(\.id)) { _, _ in
            resetSelectionIfNeeded()
        }
        .onChange(of: searchQuery) { _, _ in
            resetSelectionIfNeeded()
        }
        .onChange(of: environment.pickerCoordinator.isHistoryPresented) { _, isPresented in
            guard isPresented else {
                return
            }

            resetSelection(forceFirst: true)
            isSearchFieldFocused = true
        }
        .onMoveCommand(perform: handleMoveCommand)
        .onExitCommand {
            environment.pickerCoordinator.closeHistory()
        }
    }

    private var searchField: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)

            TextField("Search clipboard history", text: $searchQuery)
                .textFieldStyle(.plain)
                .focused($isSearchFieldFocused)
                .accessibilityLabel("Search clipboard history")
                .accessibilityHint("Filters text, rich text, and file items as you type.")

            if searchQuery.isEmpty == false {
                Button {
                    searchQuery = ""
                    isSearchFieldFocused = true
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.tertiary)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Clear search")
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color(nsColor: .textBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color(nsColor: .separatorColor), lineWidth: 1)
        )
    }

    private var emptyState: some View {
        ContentUnavailableView(
            "No Clipboard History",
            systemImage: "clipboard",
            description: Text("Copy some text or an image in another app, then open the picker again.")
        )
    }

    private var noResultsState: some View {
        ContentUnavailableView(
            "No Matches",
            systemImage: "magnifyingglass",
            description: Text("No text-based clipboard items match \"\(searchQuery)\".")
        )
    }

    private var pickerList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(filteredItems) { item in
                        HistoryPickerRow(
                            item: item,
                            thumbnailImage: environment.thumbnailService.image(
                                forRelativePath: item.previewImagePath,
                                resolvedBy: environment.historyStore
                            ),
                            isSelected: item.id == selectedItemID
                        )
                        .id(item.id)
                        .contentShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .onTapGesture {
                            selectedItemID = item.id
                        }
                        .onTapGesture(count: 2) {
                            confirmSelection(item)
                        }
                    }
                }
                .padding(.vertical, 2)
            }
            .background(Color(nsColor: .textBackgroundColor))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(Color(nsColor: .separatorColor), lineWidth: 1)
            )
            .onChange(of: selectedItemID) { _, selectedID in
                guard let selectedID else {
                    return
                }

                withAnimation(.easeInOut(duration: 0.12)) {
                    proxy.scrollTo(selectedID, anchor: .center)
                }
            }
        }
    }

    private var footer: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Keys")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("\(environment.hotkeyManager.shortcutDisplay) opens • Return pastes • Escape closes")
                    .font(.body.monospaced())
            }

            Spacer()

            Button("Paste Selected") {
                guard let selectedItem else {
                    return
                }

                confirmSelection(selectedItem)
            }
            .keyboardShortcut(.defaultAction)
            .disabled(selectedItem == nil)
            .accessibilityHint("Restores the selected clipboard item and attempts to paste it.")

            Button("Preferences…") {
                environment.pickerCoordinator.closeHistory(restoreFocus: false)
                DispatchQueue.main.async {
                    NSApp.activate(ignoringOtherApps: true)
                    openSettings()
                }
            }
            .accessibilityHint("Opens app settings and permissions.")
        }
    }

    private var permissionHint: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "hand.raised")
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 6) {
                Text(environment.permissionsService.accessibilityStatus.guidanceText)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                HStack(spacing: 10) {
                    if environment.permissionsService.accessibilityStatus == .notRequested {
                        Button("Request Access") {
                            environment.permissionsService.requestAccessibilityPermission()
                        }
                        .buttonStyle(.link)
                    }

                    Button("Open System Settings") {
                        environment.permissionsService.openSystemSettings()
                    }
                    .buttonStyle(.link)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color(nsColor: .controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private var selectedItem: ClipboardHistoryItem? {
        guard let selectedItemID else {
            return filteredItems.first
        }

        return filteredItems.first(where: { $0.id == selectedItemID })
    }

    private func confirmSelection(_ item: ClipboardHistoryItem) {
        selectedItemID = item.id
        environment.pickerCoordinator.prepareForPasteHandoff()
        environment.pickerCoordinator.closeHistory(restoreFocus: false)
        environment.pasteService.pasteSelectedItem(item)
    }

    private func handleMoveCommand(_ direction: MoveCommandDirection) {
        guard filteredItems.isEmpty == false else {
            return
        }

        switch direction {
        case .down:
            moveSelection(offset: 1)
        case .up:
            moveSelection(offset: -1)
        default:
            break
        }
    }

    private func moveSelection(offset: Int) {
        guard filteredItems.isEmpty == false else {
            return
        }

        guard
            let currentSelectionID = selectedItemID,
            let currentIndex = filteredItems.firstIndex(where: { $0.id == currentSelectionID })
        else {
            selectedItemID = filteredItems.first?.id
            return
        }

        let newIndex = max(0, min(filteredItems.count - 1, currentIndex + offset))
        selectedItemID = filteredItems[newIndex].id
    }

    private func resetSelectionIfNeeded() {
        if let selectedItemID, filteredItems.contains(where: { $0.id == selectedItemID }) {
            return
        }

        resetSelection(forceFirst: false)
    }

    private func resetSelection(forceFirst: Bool) {
        if forceFirst || selectedItemID == nil {
            selectedItemID = filteredItems.first?.id
        }
    }

    private func searchableText(for item: ClipboardHistoryItem) -> String {
        switch item.kind {
        case .text, .richText, .fileURL:
            return [item.searchText, item.textPreview, item.title, item.subtitle]
                .compactMap { $0 }
                .joined(separator: "\n")
        case .image:
            return [item.title, item.subtitle]
                .compactMap { $0 }
                .joined(separator: "\n")
        default:
            return [item.title, item.subtitle]
                .compactMap { $0 }
                .joined(separator: "\n")
        }
    }
}

private struct HistoryPickerRow: View {
    let item: ClipboardHistoryItem
    let thumbnailImage: NSImage?
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 12) {
            thumbnail

            VStack(alignment: .leading, spacing: 6) {
                Text(item.title)
                    .font(.headline)
                    .lineLimit(2)

                if let subtitle = item.subtitle {
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                if let source = item.sourceAppBundleIdentifier {
                    Text("From \(source)")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .lineLimit(1)
                }
            }

            Spacer(minLength: 0)

            Text(item.createdAt.formatted(date: .omitted, time: .shortened))
                .font(.caption.monospacedDigit())
                .foregroundStyle(.secondary)
        }
        .padding(12)
        .background(background)
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(borderColor, lineWidth: isSelected ? 1.5 : 1)
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityValue(isSelected ? "Selected" : "")
        .accessibilityHint("Double-click or press Return to paste this item.")
    }

    @ViewBuilder
    private var thumbnail: some View {
        switch item.kind {
        case .image:
            if let thumbnailImage {
                Image(nsImage: thumbnailImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 54, height: 54)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            } else {
                fallbackThumbnail(systemImage: "photo")
            }
        case .text:
            fallbackThumbnail(systemImage: "text.alignleft")
        case .richText:
            fallbackThumbnail(systemImage: "doc.richtext")
        case .fileURL:
            fallbackThumbnail(systemImage: "folder")
        default:
            fallbackThumbnail(systemImage: "doc")
        }
    }

    private func fallbackThumbnail(systemImage: String) -> some View {
        RoundedRectangle(cornerRadius: 10, style: .continuous)
            .fill(Color(nsColor: .controlBackgroundColor))
            .frame(width: 54, height: 54)
            .overlay {
                Image(systemName: systemImage)
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }
    }

    private var background: some View {
        RoundedRectangle(cornerRadius: 12, style: .continuous)
            .fill(isSelected ? Color.accentColor.opacity(0.16) : Color(nsColor: .windowBackgroundColor))
    }

    private var borderColor: Color {
        isSelected ? .accentColor : Color(nsColor: .separatorColor)
    }

    private var accessibilityLabel: String {
        [item.title, item.subtitle, item.sourceAppBundleIdentifier.map { "From \($0)" }]
            .compactMap { $0 }
            .joined(separator: ", ")
    }
}
