// swift-tools-version: 6.3.3

import PackageDescription

let package = Package(
    name: "swift-url-routing-vapor",
    platforms: [
        .macOS(.v26),
        .iOS(.v26),
    ],
    products: [
        // The URLRouting × Vapor bridge: request-data conversion from Vapor
        // requests, and router mounting onto a Vapor application.
        .library(name: "URL Routing Vapor", targets: ["URL Routing Vapor"])
    ],
    dependencies: [
        // Spelled bare to match swift-url-routing's own spelling of the same
        // upstream — one canonical location per identity across the closure.
        .package(url: "https://github.com/apple/swift-collections", from: "1.0.3"),
        .package(url: "https://github.com/swift-foundations/swift-url-routing.git", branch: "main"),
        .package(url: "https://github.com/vapor/vapor.git", from: "4.102.1"),
    ],
    targets: [
        .target(
            name: "URL Routing Vapor",
            dependencies: [
                .product(name: "OrderedCollections", package: "swift-collections"),
                .product(name: "URLRouting", package: "swift-url-routing"),
                .product(name: "Vapor", package: "vapor"),
            ]
        ),
        .testTarget(
            name: "URL Routing Vapor Tests",
            dependencies: [
                "URL Routing Vapor",
                .product(name: "VaporTesting", package: "vapor"),
            ]
        ),
    ]
)

for target in package.targets where ![.system, .binary, .plugin, .macro].contains(target.type) {
    target.swiftSettings =
        (target.swiftSettings ?? []) + [
            .enableUpcomingFeature("ExistentialAny"),
            .enableUpcomingFeature("InternalImportsByDefault"),
            .enableUpcomingFeature("MemberImportVisibility"),
            .enableUpcomingFeature("NonisolatedNonsendingByDefault"),
        ]
}
