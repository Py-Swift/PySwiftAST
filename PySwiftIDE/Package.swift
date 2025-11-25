// swift-tools-version: 6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "PySwiftIDE",
    platforms: [
        .macOS(.v13),
        .iOS(.v16)
    ],
    products: [
        .library(
            name: "PySwiftIDE",
            targets: ["PySwiftIDE"]),
        .library(
            name: "MonacoApi",
            targets: ["MonacoApi"]),
    ],
    dependencies: [
        // Local dependency on PySwiftAST
        .package(path: "../"),
    ],
    targets: [
        // Monaco Editor API types - standalone, no PySwiftAST dependency
        .target(
            name: "MonacoApi",
            dependencies: []
        ),
        
        // IDE integration layer - depends on PySwiftAST and MonacoApi
        .target(
            name: "PySwiftIDE",
            dependencies: [
                .product(name: "PySwiftAST", package: "PySwiftAST"),
                .product(name: "PySwiftCodeGen", package: "PySwiftAST"),
                "MonacoApi",
            ]
        ),
        .testTarget(
            name: "PySwiftIDETests",
            dependencies: ["PySwiftIDE", "MonacoApi"]
        ),
    ]
)
