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
        .library(
            name: "PyFormatters",
            targets: ["PyFormatters"]),
        .library(
            name: "PyChecking",
            targets: ["PyChecking"]),
        .library(
            name: "PyAstVisitors",
            targets: ["PyAstVisitors"]),
        .executable(
            name: "pyswift-benchmark",
            targets: ["pyswift-benchmark"]),
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
        .target(
            name: "PyFormatters",
            dependencies: [
                "PySwiftAST",
                "PySwiftCodeGen"
            ]
        ),
        .target(
            name: "PyChecking",
            dependencies: [
                "PySwiftAST",
                "PySwiftCodeGen"
            ]
        ),
        .target(
            name: "PyAstVisitors",
            dependencies: [
                "PySwiftAST"
            ]
        ),
        .executableTarget(
            name: "pyswift-benchmark",
            dependencies: ["PySwiftAST", "PySwiftCodeGen"]
        ),
        .testTarget(
            name: "PySwiftASTTests",
            dependencies: ["PySwiftAST", "PyChecking"],
            resources: [
                .copy("Resources")
            ]
        ),
        .testTarget(
            name: "PySwiftCodeGenTests",
            dependencies: ["PySwiftCodeGen", "PySwiftAST"]
        ),
        .testTarget(
            name: "PyAstVisitorsTests",
            dependencies: ["PyAstVisitors", "PySwiftAST"]
        ),
    ]
)
