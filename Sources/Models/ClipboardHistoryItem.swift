import Foundation

struct ClipboardHistoryItem: Identifiable, Codable {
    let id: UUID
    let createdAt: Date
    let sourceAppBundleIdentifier: String?
    let kind: ClipboardItemKind
    let title: String
    let subtitle: String?
    let searchText: String?
    let previewImagePath: String?
    let payloadStoragePath: String?
    let textPreview: String?
    let imageWidth: Int?
    let imageHeight: Int?
    let utiTypes: [String]
    let byteSize: Int64
    let payloadFingerprint: String
}

enum ClipboardItemKind: String, CaseIterable, Hashable, Codable {
    case text
    case richText
    case image
    case fileURL
    case html
    case unknown
}
