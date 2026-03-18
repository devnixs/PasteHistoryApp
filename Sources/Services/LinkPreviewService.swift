import AppKit
import Combine
import Foundation
import LinkPresentation

@MainActor
final class LinkPreviewService: ObservableObject {
    private let faviconCache = NSCache<NSURL, NSImage>()
    private var pendingTasks: [URL: Task<NSImage?, Never>] = [:]

    func favicon(for url: URL) async -> NSImage? {
        if let cachedImage = faviconCache.object(forKey: url as NSURL) {
            return cachedImage
        }

        if let pendingTask = pendingTasks[url] {
            return await pendingTask.value
        }

        let task = Task<NSImage?, Never> {
            defer { Task { @MainActor in self.pendingTasks[url] = nil } }

            let provider = LPMetadataProvider()
            provider.timeout = 8

            do {
                let metadata = try await provider.startFetchingMetadata(for: url)
                if
                    let iconProvider = metadata.iconProvider,
                    let image = try await loadImage(from: iconProvider)
                {
                    await MainActor.run {
                        faviconCache.setObject(image, forKey: url as NSURL)
                    }
                    return image
                }

                if
                    let imageProvider = metadata.imageProvider,
                    let image = try await loadImage(from: imageProvider)
                {
                    await MainActor.run {
                        faviconCache.setObject(image, forKey: url as NSURL)
                    }
                    return image
                }
            } catch {
                NSLog("LinkPreviewService failed for \(url.absoluteString): \(error.localizedDescription)")
            }

            return nil
        }

        pendingTasks[url] = task
        return await task.value
    }

    private func loadImage(from provider: NSItemProvider) async throws -> NSImage? {
        if provider.canLoadObject(ofClass: NSImage.self) {
            return try await withCheckedThrowingContinuation { continuation in
                _ = provider.loadObject(ofClass: NSImage.self) { object, error in
                    if let error {
                        continuation.resume(throwing: error)
                        return
                    }

                    continuation.resume(returning: object as? NSImage)
                }
            }
        }

        return nil
    }
}
