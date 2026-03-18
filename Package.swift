// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "PasteHistoryApp",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "PasteHistoryApp", targets: ["PasteHistoryApp"])
    ],
    targets: [
        .executableTarget(
            name: "PasteHistoryApp",
            path: "Sources"
        )
    ]
)
