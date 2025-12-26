// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "PyModuleDumper",
    products: [
        // Products can be used to vend plugins, making them visible to other packages.
        .plugin(
            name: "PyModuleDumper",
            targets: ["PyModuleDumper"]
        ),
    ],
    dependencies: [
        .package(path: "../")
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "PyLibFiles",
            resources: [
                .copy("python3.13")
            ]
        ),
        .executableTarget(
            name: "PyModuleDump",
            dependencies: [
                .product(name: "PySwiftAST", package: "PySwiftAST"),
                .product(name: "PySwiftCodeGen", package: "PySwiftAST"),
                "PyLibFiles"
            ]
        ),
        .plugin(
            name: "PyModuleDumper",
            capability: .command(intent: .custom(
                verb: "PyModuleDumper",
                description: "prints hello world"
            ))
        ),
    ]
)
