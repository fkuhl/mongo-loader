// swift-tools-version:5.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "mongo-loader",
    dependencies: [
        .package(url: "https://github.com/mongodb/mongo-swift-driver.git", from: "0.2.0"),
        .package(url: "https://github.com/fkuhl/PMDataTypes.git", from: "2.0.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages which this package depends on.
        .target(
            name: "mongo-loader",
            dependencies: ["MongoSwift", "PMDataTypes"]),
        .testTarget(
            name: "mongo-loaderTests",
            dependencies: ["mongo-loader"]),
    ]
)
