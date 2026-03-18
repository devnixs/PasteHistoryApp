import AppKit
import CryptoKit
import Foundation

struct ClipboardNormalizer {
    static let maxTextBytes = 1_000_000
    static let maxImageBytes = 20_000_000
    static let maxPreviewLength = 160

    func normalizeCurrentContents(
        of pasteboard: NSPasteboard,
        sourceAppBundleIdentifier: String?
    ) -> NormalizedClipboardItem? {
        let utiTypes = pasteboard.pasteboardItems?
            .flatMap { $0.types.map(\.rawValue) } ?? pasteboard.types?.map(\.rawValue) ?? []

        if let item = normalizeFileURLs(from: pasteboard, utiTypes: utiTypes, sourceAppBundleIdentifier: sourceAppBundleIdentifier) {
            return item
        }

        if let item = normalizeRichText(from: pasteboard, utiTypes: utiTypes, sourceAppBundleIdentifier: sourceAppBundleIdentifier) {
            return item
        }

        if let item = normalizeText(from: pasteboard, utiTypes: utiTypes, sourceAppBundleIdentifier: sourceAppBundleIdentifier) {
            return item
        }

        if let item = normalizeImage(from: pasteboard, utiTypes: utiTypes, sourceAppBundleIdentifier: sourceAppBundleIdentifier) {
            return item
        }

        return nil
    }

    private func normalizeFileURLs(
        from pasteboard: NSPasteboard,
        utiTypes: [String],
        sourceAppBundleIdentifier: String?
    ) -> NormalizedClipboardItem? {
        guard
            let urls = pasteboard.readObjects(forClasses: [NSURL.self], options: nil) as? [URL],
            urls.isEmpty == false
        else {
            return nil
        }

        let fileURLs = urls.filter(\.isFileURL)
        guard fileURLs.isEmpty == false else {
            return nil
        }

        let displayNames = fileURLs.map { $0.lastPathComponent.isEmpty ? $0.path : $0.lastPathComponent }
        let title = displayNames.count == 1 ? displayNames[0] : "\(displayNames.count) files"
        let subtitle = fileURLs.count == 1 ? fileURLs[0].path : displayNames.joined(separator: ", ")
        let searchText = fileURLs.map(\.path).joined(separator: "\n")

        let encoder = JSONEncoder()
        guard let payloadData = try? encoder.encode(fileURLs.map(\.absoluteString)) else {
            return nil
        }

        let item = ClipboardHistoryItem(
            id: UUID(),
            createdAt: Date(),
            sourceAppBundleIdentifier: sourceAppBundleIdentifier,
            kind: .fileURL,
            title: title,
            subtitle: subtitle,
            searchText: searchText,
            previewImagePath: nil,
            payloadStoragePath: nil,
            textPreview: title,
            imageWidth: nil,
            imageHeight: nil,
            utiTypes: utiTypes,
            byteSize: Int64(payloadData.count),
            payloadFingerprint: fingerprint(for: payloadData, kind: .fileURL)
        )

        return NormalizedClipboardItem(
            item: item,
            payloadData: payloadData,
            payloadFileExtension: "json"
        )
    }

    private func normalizeRichText(
        from pasteboard: NSPasteboard,
        utiTypes: [String],
        sourceAppBundleIdentifier: String?
    ) -> NormalizedClipboardItem? {
        guard let rtfData = pasteboard.data(forType: .rtf) else {
            return nil
        }

        guard rtfData.count <= Self.maxTextBytes else {
            return nil
        }

        let attributedString = NSAttributedString(rtf: rtfData, documentAttributes: nil)
        let plainText = attributedString?.string ?? pasteboard.string(forType: .string) ?? ""
        let trimmedPreview = plainText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmedPreview.isEmpty == false else {
            return nil
        }

        let preview = makePreview(from: trimmedPreview)
        let item = ClipboardHistoryItem(
            id: UUID(),
            createdAt: Date(),
            sourceAppBundleIdentifier: sourceAppBundleIdentifier,
            kind: .richText,
            title: preview,
            subtitle: "Rich Text • \(textSubtitle(for: rtfData.count))",
            searchText: plainText,
            previewImagePath: nil,
            payloadStoragePath: nil,
            textPreview: preview,
            imageWidth: nil,
            imageHeight: nil,
            utiTypes: utiTypes,
            byteSize: Int64(rtfData.count),
            payloadFingerprint: fingerprint(for: rtfData, kind: .richText)
        )

        return NormalizedClipboardItem(
            item: item,
            payloadData: rtfData,
            payloadFileExtension: "rtf"
        )
    }

    private func normalizeText(
        from pasteboard: NSPasteboard,
        utiTypes: [String],
        sourceAppBundleIdentifier: String?
    ) -> NormalizedClipboardItem? {
        guard let text = pasteboard.string(forType: .string) else {
            return nil
        }

        let trimmedPreview = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmedPreview.isEmpty == false else {
            return nil
        }

        guard let data = text.data(using: .utf8) else {
            return nil
        }

        guard data.count <= Self.maxTextBytes else {
            return nil
        }

        let preview = makePreview(from: trimmedPreview)
        let byteSize = Int64(data.count)
        let item = ClipboardHistoryItem(
            id: UUID(),
            createdAt: Date(),
            sourceAppBundleIdentifier: sourceAppBundleIdentifier,
            kind: .text,
            title: preview,
            subtitle: textSubtitle(for: data.count),
            searchText: text,
            previewImagePath: nil,
            payloadStoragePath: nil,
            textPreview: preview,
            imageWidth: nil,
            imageHeight: nil,
            utiTypes: utiTypes,
            byteSize: byteSize,
            payloadFingerprint: fingerprint(for: data, kind: .text)
        )

        return NormalizedClipboardItem(
            item: item,
            payloadData: data,
            payloadFileExtension: "txt"
        )
    }

    private func normalizeImage(
        from pasteboard: NSPasteboard,
        utiTypes: [String],
        sourceAppBundleIdentifier: String?
    ) -> NormalizedClipboardItem? {
        guard let image = NSImage(pasteboard: pasteboard) else {
            return nil
        }

        guard let imageData = imageData(from: pasteboard, image: image) else {
            return nil
        }

        guard imageData.count <= Self.maxImageBytes else {
            return nil
        }

        let size = imageSize(for: image)
        let dimensionSummary = imageSubtitle(width: size.width, height: size.height, byteCount: imageData.count)
        let item = ClipboardHistoryItem(
            id: UUID(),
            createdAt: Date(),
            sourceAppBundleIdentifier: sourceAppBundleIdentifier,
            kind: .image,
            title: imageTitle(width: size.width, height: size.height),
            subtitle: dimensionSummary,
            searchText: dimensionSummary,
            previewImagePath: nil,
            payloadStoragePath: nil,
            textPreview: nil,
            imageWidth: Int(size.width),
            imageHeight: Int(size.height),
            utiTypes: utiTypes,
            byteSize: Int64(imageData.count),
            payloadFingerprint: fingerprint(for: imageData, kind: .image)
        )

        return NormalizedClipboardItem(
            item: item,
            payloadData: imageData,
            payloadFileExtension: "png"
        )
    }

    private func imageData(from pasteboard: NSPasteboard, image: NSImage) -> Data? {
        let imageTypes: [NSPasteboard.PasteboardType] = [.png, .tiff]

        for type in imageTypes {
            if let data = pasteboard.data(forType: type) {
                return data
            }
        }

        guard
            let tiffData = image.tiffRepresentation,
            let bitmap = NSBitmapImageRep(data: tiffData)
        else {
            return nil
        }

        return bitmap.representation(using: .png, properties: [:]) ?? tiffData
    }

    private func imageSize(for image: NSImage) -> CGSize {
        if image.size.width > 0, image.size.height > 0 {
            return image.size
        }

        if
            let tiffData = image.tiffRepresentation,
            let bitmap = NSBitmapImageRep(data: tiffData)
        {
            return CGSize(width: bitmap.pixelsWide, height: bitmap.pixelsHigh)
        }

        return .zero
    }

    private func makePreview(from text: String) -> String {
        let collapsedWhitespace = text
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { $0.isEmpty == false }
            .joined(separator: " ")

        if collapsedWhitespace.count <= Self.maxPreviewLength {
            return collapsedWhitespace
        }

        let truncated = collapsedWhitespace.prefix(Self.maxPreviewLength)
        return "\(truncated)…"
    }

    private func textSubtitle(for byteCount: Int) -> String {
        ByteCountFormatter.string(fromByteCount: Int64(byteCount), countStyle: .file)
    }

    private func imageTitle(width: CGFloat, height: CGFloat) -> String {
        if width > 0, height > 0 {
            return "Image \(Int(width))×\(Int(height))"
        }

        return "Image"
    }

    private func imageSubtitle(width: CGFloat, height: CGFloat, byteCount: Int) -> String {
        var parts: [String] = []

        if width > 0, height > 0 {
            parts.append("\(Int(width))×\(Int(height))")
        }

        parts.append(ByteCountFormatter.string(fromByteCount: Int64(byteCount), countStyle: .file))
        return parts.joined(separator: " • ")
    }

    private func fingerprint(for data: Data, kind: ClipboardItemKind) -> String {
        let digest = SHA256.hash(data: data)
        let hexDigest = digest.map { String(format: "%02x", $0) }.joined()
        return "\(kind.rawValue):\(hexDigest)"
    }
}
