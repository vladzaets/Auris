// swift-tools-version: 6.1
import PackageDescription

let package = Package(
    name: "Auris",
    platforms: [.macOS("15.4")],
    dependencies: [],
    targets: [
        .binaryTarget(
            name: "CWhisper",
            path: "Frameworks/CWhisper.xcframework"
        ),
        .executableTarget(
            name: "Auris",
            dependencies: [
                "CWhisper",
            ],
            path: "Sources/Auris"
        ),
    ]
)
