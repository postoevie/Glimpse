// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "GlimpseAI",
    platforms: [.iOS("26.0"), .macOS("26.0")],
    products: [
        .library(name: "GlimpseAI", targets: ["GlimpseAI"]),
    ],
    dependencies: [
        .package(path: "../GlimpseCore"),
    ],
    targets: [
        .target(
            name: "GlimpseAI",
            dependencies: ["GlimpseCore"]
        ),
    ]
)
