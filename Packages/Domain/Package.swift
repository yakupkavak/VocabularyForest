// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Domain",
    platforms: [.iOS(.v16)],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "Domain",
            targets: ["Domain", "DTO"]
        ),
        .library(name: "DomainMocks", targets: ["DomainMocks"])
    ],
    dependencies: [
        .package(url: "https://github.com/yakupkavak/YakoSwift", from: "1.0.0"),
        .package(path: "../CoreAPI")
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "Domain" // Buna dependencies eklersen eğer import dto yapabilirsin
        ),
        .target(
            name: "DTO",
            dependencies: [
                .product(name: "CoreAPI", package: "CoreAPI")
            ]
        ),
        .target(
            name: "DomainMocks",
            dependencies: ["Domain", "DTO"]
        ),
        .testTarget(
            name: "DomainTests",
            dependencies: ["Domain"]
        ),
    ]
)
