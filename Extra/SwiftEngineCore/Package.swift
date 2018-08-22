// swift-tools-version:4.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SwiftEngine",
    products: [
        // Products define the executables and libraries produced by a package, and make them visible to other packages.
        .library(
            name: "SwiftEngine",
            type: .dynamic, 
            //type: .static,
            targets: ["SwiftEngine"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        .package(url: "https://github.com/IBM-Swift/SwiftyJSON", from: "17.0.2"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages which this package depends on.
        .target(
            name: "SwiftEngine",
            dependencies: [
				"SwiftyJSON",
//				"MongoKitten"//, "ExtendedJSON"
            ],
            path: "Sources/SwiftEngineCore"
            ),
        .testTarget(
            name: "SwiftEngineTest",
            dependencies: ["SwiftEngine"],
            path: "Tests/SwiftEngineCoreTests"),
    ]
)
