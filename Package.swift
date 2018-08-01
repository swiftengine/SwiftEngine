// swift-tools-version:4.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SwiftEngine",
    products: [
        // Products define the executables and libraries produced by a package, and make them visible to other packages.
        .executable(
            name: "SwiftEngine",
            targets: ["SwiftEngine"]),
        .executable(
            name: "SEProcessor",
            targets: ["SEProcessor"]),
        .library(
            name: "SECore",
            targets: ["SECore"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        .package(url: "https://github.com/apple/swift-nio.git", from: "1.7.3"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages which this package depends on.
        .target(
            name: "SwiftEngine",
            dependencies: ["NIO", "NIOHTTP1"]), 
        .target(
            name: "SEProcessor",
            dependencies: ["SEProcessorLib"]),
		.target(
			name: "SEProcessorLib",
			dependencies: []),
        .target(
            name: "SECore",
            dependencies: [
//				"SwiftyJSON",
//				"MongoKitten"//, "ExtendedJSON"
            ]),

        .testTarget(
            name: "SwiftEngineTests",
            dependencies: ["SwiftEngine"]),
        .testTarget(
            name: "SEProcessorLibTests",
            dependencies: ["SwiftEngine"]),
        .testTarget(
            name: "SEProcessorTests",
            dependencies: ["SwiftEngine"]),
        .testTarget(
            name: "SECoreTests",
            dependencies: ["SwiftEngine"]),
    ]
)
