// swift-tools-version: 6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "PySwiftAST",
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "PySwiftAST",
            targets: ["PySwiftAST"]),
        .library(
            name: "PySwiftCodeGen",
            targets: ["PySwiftCodeGen"]),
        .executable(
            name: "pyswift-benchmark",
            targets: ["PySwiftBenchmark"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-algorithms", from: "1.2.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "PySwiftAST",
            dependencies: [
                .product(name: "Algorithms", package: "swift-algorithms")
            ],
            resources: [
                .copy("AST/README.md")
            ]
        ),
        .target(
            name: "PySwiftCodeGen",
            dependencies: [
                "PySwiftAST",
                .product(name: "Algorithms", package: "swift-algorithms")
            ]
        ),
        .executableTarget(
            name: "PySwiftBenchmark",
            dependencies: ["PySwiftAST", "PySwiftCodeGen"]
        ),
        .testTarget(
            name: "PySwiftASTTests",
            dependencies: ["PySwiftAST"],
            resources: [
                .copy("Resources")
            ]
        ),
        .testTarget(
            name: "PySwiftCodeGenTests",
            dependencies: ["PySwiftCodeGen", "PySwiftAST"]
        ),
    ]
)
