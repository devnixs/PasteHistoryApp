import AppKit
import Combine
import Foundation

@MainActor
final class ThumbnailService: ObservableObject {
    private let targetSize = CGSize(width: 108, height: 108)
    private let imageCache = NSCache<NSString, NSImage>()

    func generateThumbnail(
        for itemID: UUID,
        imageData: Data,
        in thumbnailsDirectoryURL: URL
    ) throws -> String? {
        guard
            let sourceImage = NSImage(data: imageData),
            let thumbnailImage = resizedImage(from: sourceImage)
        else {
            return nil
        }

        let fileName = "\(itemID.uuidString).png"
        let fileURL = thumbnailsDirectoryURL.appendingPathComponent(fileName, isDirectory: false)
        guard let pngData = pngData(from: thumbnailImage) else {
            return nil
        }

        try pngData.write(to: fileURL, options: .atomic)
        imageCache.setObject(thumbnailImage, forKey: fileName as NSString)
        return "thumbnails/\(fileName)"
    }

    func image(forRelativePath relativePath: String?, resolvedBy historyStore: HistoryStore) -> NSImage? {
        guard let relativePath else {
            return nil
        }

        let cacheKey = relativePath as NSString
        if let cachedImage = imageCache.object(forKey: cacheKey) {
            return cachedImage
        }

        guard
            let fileURL = historyStore.fileURL(forRelativePath: relativePath),
            let image = NSImage(contentsOf: fileURL)
        else {
            return nil
        }

        imageCache.setObject(image, forKey: cacheKey)
        return image
    }

    private func resizedImage(from image: NSImage) -> NSImage? {
        let imageSize = image.size
        guard imageSize.width > 0, imageSize.height > 0 else {
            return nil
        }

        let scale = min(targetSize.width / imageSize.width, targetSize.height / imageSize.height)
        let scaledSize = CGSize(
            width: max(1, floor(imageSize.width * scale)),
            height: max(1, floor(imageSize.height * scale))
        )

        let thumbnail = NSImage(size: targetSize)
        thumbnail.lockFocus()
        NSColor.clear.setFill()
        NSBezierPath(rect: NSRect(origin: .zero, size: targetSize)).fill()

        let origin = CGPoint(
            x: (targetSize.width - scaledSize.width) / 2,
            y: (targetSize.height - scaledSize.height) / 2
        )
        image.draw(
            in: NSRect(origin: origin, size: scaledSize),
            from: NSRect(origin: .zero, size: imageSize),
            operation: .copy,
            fraction: 1
        )
        thumbnail.unlockFocus()
        return thumbnail
    }

    private func pngData(from image: NSImage) -> Data? {
        guard
            let tiffData = image.tiffRepresentation,
            let bitmap = NSBitmapImageRep(data: tiffData)
        else {
            return nil
        }

        return bitmap.representation(using: .png, properties: [:])
    }
}
