// swift-tools-version:4.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SwiftEngine",
    products: [
        // Products define the executables and libraries produced by a package, and make them visible to other packages.
        .executable(
            name: "SwiftEngineServer",
            targets: ["SwiftEngineServer"]),
        .executable(
            name: "SEProcessor",
            targets: ["SEProcessor"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        .package(url: "https://github.com/apple/swift-nio.git", from: "1.7.3"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages which this package depends on.
        .target(
            name: "SwiftEngineServer",
            dependencies: ["NIO", "NIOHTTP1", "NIOFoundationCompat"]), 
        .target(
            name: "SEProcessor",
            dependencies: ["SEProcessorLib"]),
		.target(
			name: "SEProcessorLib",
			dependencies: []),

        .testTarget(
            name: "SwiftEngineServerTests",
            dependencies: ["SwiftEngineServer"]),
        .testTarget(
            name: "SEProcessorLibTests",
            dependencies: ["SwiftEngineServer"]),
        .testTarget(
            name: "SEProcessorTests",
            dependencies: ["SwiftEngineServer"]),
    ]
)
