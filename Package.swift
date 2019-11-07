// swift-tools-version:5.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package (
    name: "ProcessOut",
    products: [
        .library(name: "ProcessOut", targets: ["ProcessOut"])
    ],
    targets: [
        .target(
            name: "ProcessOut",
            dependencies: [],
            path: "ProcessOut"
        ),
    ],
    swiftLanguageVersions: [.v5]
)
