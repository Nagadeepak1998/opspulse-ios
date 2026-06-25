// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "OpsPulse",
    platforms: [
        .macOS(.v15),
        .iOS(.v18)
    ],
    products: [
        .library(name: "OpsPulseCore", targets: ["OpsPulseCore"])
    ],
    targets: [
        .target(
            name: "OpsPulseCore",
            path: "Sources/OpsPulseCore"
        ),
        .testTarget(
            name: "OpsPulseCoreTests",
            dependencies: ["OpsPulseCore"],
            path: "Tests/OpsPulseCoreTests"
        )
    ]
)
