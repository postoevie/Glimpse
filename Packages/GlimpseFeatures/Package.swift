// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "GlimpseFeatures",
    platforms: [.iOS("26.0")],
    products: [
        .library(name: "GlimpseFeatures", targets: ["GlimpseFeatures"]),
    ],
    dependencies: [
        .package(path: "../GlimpseCore"),
        .package(path: "../GlimpseAI"),
        .package(
            url: "https://github.com/pointfreeco/swift-composable-architecture",
            from: "1.25.0"
        ),
    ],
    targets: [
        .target(
            name: "GlimpseFeatures",
            dependencies: [
                "GlimpseCore",
                "GlimpseAI",
                .product(
                    name: "ComposableArchitecture",
                    package: "swift-composable-architecture"
                ),
            ]
        ),
    ]
)
