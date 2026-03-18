import Combine
import Foundation

@MainActor
final class HistoryStore: ObservableObject {
    @Published private(set) var items: [ClipboardHistoryItem]
    private let settingsStore: SettingsStore
    private let thumbnailService: ThumbnailService
    private let fileManager: FileManager
    private let storageDirectoryURL: URL
    private let blobsDirectoryURL: URL
    private let thumbnailsDirectoryURL: URL
    private let metadataFileURL: URL

    init(
        settingsStore: SettingsStore,
        thumbnailService: ThumbnailService,
        fileManager: FileManager = .default
    ) {
        self.settingsStore = settingsStore
        self.thumbnailService = thumbnailService
        self.fileManager = fileManager

        let applicationSupportURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? fileManager.homeDirectoryForCurrentUser.appendingPathComponent("Library/Application Support", isDirectory: true)
        let storageDirectoryURL = applicationSupportURL
            .appendingPathComponent("PasteHistoryApp", isDirectory: true)
        self.storageDirectoryURL = storageDirectoryURL
        self.blobsDirectoryURL = storageDirectoryURL.appendingPathComponent("blobs", isDirectory: true)
        self.thumbnailsDirectoryURL = storageDirectoryURL.appendingPathComponent("thumbnails", isDirectory: true)
        self.metadataFileURL = storageDirectoryURL.appendingPathComponent("history.json", isDirectory: false)

        self.items = []

        do {
            try fileManager.createDirectory(at: self.blobsDirectoryURL, withIntermediateDirectories: true, attributes: nil)
            try fileManager.createDirectory(at: self.thumbnailsDirectoryURL, withIntermediateDirectories: true, attributes: nil)
            self.items = try loadPersistedItems()
            cleanupOrphanedFiles()
            let removedItems = pruneItemsInMemory()
            try persistMetadata()
            cleanupFiles(for: removedItems)
        } catch {
            self.items = []
            NSLog("HistoryStore initialization failed: \(error.localizedDescription)")
        }
    }

    func capture(_ normalizedItem: NormalizedClipboardItem) {
        guard shouldStore(normalizedItem.item) else {
            return
        }

        do {
            let storedItem = try persist(normalizedItem)
            items.insert(storedItem, at: 0)
            let removedItems = pruneItemsInMemory()
            try persistMetadata()
            cleanupFiles(for: removedItems)
        } catch {
            NSLog("HistoryStore capture failed: \(error.localizedDescription)")
        }
    }

    func clearHistory() {
        let removedItems = items
        items.removeAll()
        do {
            try persistMetadata()
        } catch {
            NSLog("HistoryStore clear failed: \(error.localizedDescription)")
        }
        cleanupFiles(for: removedItems)
    }

    func reapplyRetentionPolicies() {
        let removedItems = pruneItemsInMemory()
        do {
            try persistMetadata()
        } catch {
            NSLog("HistoryStore retention update failed: \(error.localizedDescription)")
        }
        cleanupFiles(for: removedItems)
    }

    func fileURL(forRelativePath relativePath: String?) -> URL? {
        guard let relativePath else {
            return nil
        }

        return storageDirectoryURL.appendingPathComponent(relativePath, isDirectory: false)
    }

    var itemCount: Int {
        items.count
    }

    var totalStorageDescription: String {
        ByteCountFormatter.string(fromByteCount: totalStoredBytes, countStyle: .file)
    }

    private func shouldStore(_ item: ClipboardHistoryItem) -> Bool {
        guard let latest = items.first else {
            return true
        }

        if latest.kind != item.kind {
            return true
        }

        return latest.payloadFingerprint != item.payloadFingerprint
    }

    private func persist(_ normalizedItem: NormalizedClipboardItem) throws -> ClipboardHistoryItem {
        let payloadFileName = "\(normalizedItem.item.id.uuidString).\(normalizedItem.payloadFileExtension)"
        let payloadRelativePath = "blobs/\(payloadFileName)"
        let payloadURL = blobsDirectoryURL.appendingPathComponent(payloadFileName, isDirectory: false)

        try normalizedItem.payloadData.write(to: payloadURL, options: .atomic)

        let previewImagePath: String?
        if normalizedItem.item.kind == .image {
            previewImagePath = try thumbnailService.generateThumbnail(
                for: normalizedItem.item.id,
                imageData: normalizedItem.payloadData,
                in: thumbnailsDirectoryURL
            )
        } else {
            previewImagePath = normalizedItem.item.previewImagePath
        }

        return ClipboardHistoryItem(
            id: normalizedItem.item.id,
            createdAt: normalizedItem.item.createdAt,
            sourceAppBundleIdentifier: normalizedItem.item.sourceAppBundleIdentifier,
            kind: normalizedItem.item.kind,
            title: normalizedItem.item.title,
            subtitle: normalizedItem.item.subtitle,
            searchText: normalizedItem.item.searchText,
            previewImagePath: previewImagePath,
            payloadStoragePath: payloadRelativePath,
            textPreview: normalizedItem.item.textPreview,
            imageWidth: normalizedItem.item.imageWidth,
            imageHeight: normalizedItem.item.imageHeight,
            utiTypes: normalizedItem.item.utiTypes,
            byteSize: normalizedItem.item.byteSize,
            payloadFingerprint: normalizedItem.item.payloadFingerprint
        )
    }

    private func loadPersistedItems() throws -> [ClipboardHistoryItem] {
        guard fileManager.fileExists(atPath: metadataFileURL.path) else {
            return []
        }

        do {
            let data = try Data(contentsOf: metadataFileURL)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601

            let history = try decoder.decode(PersistedHistory.self, from: data)
            return history.items
                .filter { item in
                    guard let payloadStoragePath = item.payloadStoragePath else {
                        return true
                    }

                    return fileManager.fileExists(atPath: storageDirectoryURL.appendingPathComponent(payloadStoragePath).path)
                }
                .sorted { $0.createdAt > $1.createdAt }
        } catch {
            NSLog("HistoryStore failed to decode persisted metadata: \(error.localizedDescription)")
            return []
        }
    }

    private func persistMetadata() throws {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

        let data = try encoder.encode(PersistedHistory(items: items))
        do {
            try data.write(to: metadataFileURL, options: .atomic)
        } catch {
            NSLog("HistoryStore failed to persist metadata: \(error.localizedDescription)")
            throw error
        }
    }

    private func pruneItemsInMemory() -> [ClipboardHistoryItem] {
        var removedItems: [ClipboardHistoryItem] = []
        let now = Date()

        if settingsStore.autoExpireEnabled {
            let cutoffDate = Calendar.current.date(byAdding: .day, value: -settingsStore.autoExpireDays, to: now) ?? now
            let expiredItems = items.filter { $0.createdAt < cutoffDate }
            if expiredItems.isEmpty == false {
                NSLog("HistoryStore pruning \(expiredItems.count) expired item(s) older than \(cutoffDate).")
            }
            removedItems.append(contentsOf: expiredItems)
            items.removeAll { $0.createdAt < cutoffDate }
        }

        if items.count > settingsStore.maxHistoryItems {
            let overflowCount = items.count - settingsStore.maxHistoryItems
            let countPruned = Array(items.suffix(overflowCount))
            NSLog("HistoryStore pruning \(countPruned.count) item(s) to satisfy max item count \(settingsStore.maxHistoryItems).")
            removedItems.append(contentsOf: countPruned)
            items.removeLast(overflowCount)
        }

        let maxStorageBytes = Int64(settingsStore.storageCapMB) * 1_024 * 1_024
        let sizePruned = pruneForSizeLimit(maxStorageBytes)
        if sizePruned.isEmpty == false {
            NSLog("HistoryStore pruning \(sizePruned.count) item(s) to satisfy storage cap \(settingsStore.storageCapMB) MB.")
        }
        removedItems.append(contentsOf: sizePruned)

        return deduplicatedRemovedItems(removedItems)
    }

    private func pruneForSizeLimit(_ maxStorageBytes: Int64) -> [ClipboardHistoryItem] {
        guard totalStoredBytes > maxStorageBytes else {
            return []
        }

        var removedItems: [ClipboardHistoryItem] = []
        while totalStoredBytes > maxStorageBytes, let candidate = nextSizePruneCandidate() {
            items.removeAll { $0.id == candidate.id }
            removedItems.append(candidate)
        }

        return removedItems
    }

    private func nextSizePruneCandidate() -> ClipboardHistoryItem? {
        let staleImageCandidate = items
            .filter { $0.kind == .image }
            .sorted { lhs, rhs in
                if lhs.createdAt == rhs.createdAt {
                    return lhs.byteSize > rhs.byteSize
                }
                return lhs.createdAt < rhs.createdAt
            }
            .first

        if let staleImageCandidate {
            return staleImageCandidate
        }

        return items.min { lhs, rhs in
            lhs.createdAt < rhs.createdAt
        }
    }

    private func deduplicatedRemovedItems(_ items: [ClipboardHistoryItem]) -> [ClipboardHistoryItem] {
        var seen = Set<UUID>()
        return items.filter { item in
            seen.insert(item.id).inserted
        }
    }

    private var totalStoredBytes: Int64 {
        items.reduce(0) { partialResult, item in
            partialResult + item.byteSize
        }
    }

    private func cleanupFiles(for items: [ClipboardHistoryItem]) {
        for item in items {
            if let payloadStoragePath = item.payloadStoragePath {
                removeFileIfNeeded(at: storageDirectoryURL.appendingPathComponent(payloadStoragePath))
            }

            if let previewImagePath = item.previewImagePath {
                removeFileIfNeeded(at: storageDirectoryURL.appendingPathComponent(previewImagePath))
            }
        }
    }

    private func cleanupOrphanedFiles() {
        let referencedRelativePaths = Set(
            items.flatMap { item in
                [item.payloadStoragePath, item.previewImagePath].compactMap { $0 }
            }
        )

        cleanupOrphanedFiles(in: blobsDirectoryURL, referencedRelativePaths: referencedRelativePaths, relativeRoot: "blobs")
        cleanupOrphanedFiles(in: thumbnailsDirectoryURL, referencedRelativePaths: referencedRelativePaths, relativeRoot: "thumbnails")
    }

    private func cleanupOrphanedFiles(in directoryURL: URL, referencedRelativePaths: Set<String>, relativeRoot: String) {
        guard let enumerator = fileManager.enumerator(at: directoryURL, includingPropertiesForKeys: nil) else {
            return
        }

        for case let fileURL as URL in enumerator {
            let relativePath = "\(relativeRoot)/\(fileURL.lastPathComponent)"
            guard referencedRelativePaths.contains(relativePath) == false else {
                continue
            }

            removeFileIfNeeded(at: fileURL)
            NSLog("HistoryStore removed orphaned file at \(relativePath).")
        }
    }

    private func removeFileIfNeeded(at url: URL) {
        guard fileManager.fileExists(atPath: url.path) else {
            return
        }

        do {
            try fileManager.removeItem(at: url)
        } catch {
            NSLog("HistoryStore cleanup failed for \(url.path): \(error.localizedDescription)")
        }
    }
}

private struct PersistedHistory: Codable {
    let items: [ClipboardHistoryItem]
}
