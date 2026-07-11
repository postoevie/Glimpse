// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "GlimpseCore",
    platforms: [.iOS("26.0")],
    products: [
        .library(name: "GlimpseCore", targets: ["GlimpseCore"]),
    ],
    targets: [
        .target(name: "GlimpseCore"),
    ]
)
