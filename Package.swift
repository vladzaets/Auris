// swift-tools-version: 6.1
import PackageDescription

let package = Package(
    name: "Auris",
    platforms: [.macOS("15.4")],
    dependencies: [
        .package(path: "../mlx-swift-audio"),
    ],
    targets: [
        .executableTarget(
            name: "Auris",
            dependencies: [
                .product(name: "MLXAudio", package: "mlx-swift-audio"),
            ],
            path: "Sources/Auris"
        ),
    ]
)
