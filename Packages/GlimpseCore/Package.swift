// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "GlimpseCore",
    platforms: [.iOS("26.0"), .macOS("26.0")],
    products: [
        .library(name: "GlimpseCore", targets: ["GlimpseCore"]),
    ],
    dependencies: [
        .package(
            url: "https://github.com/pointfreeco/xctest-dynamic-overlay",
            from: "1.0.0"
        ),
    ],
    targets: [
        .target(
            name: "GlimpseCore",
            dependencies: [
                .product(name: "IssueReporting", package: "xctest-dynamic-overlay"),
            ]
        ),
        .testTarget(
            name: "GlimpseCoreTests",
            dependencies: [
                "GlimpseCore",
                .product(name: "IssueReporting", package: "xctest-dynamic-overlay"),
            ]
        ),
    ]
)
