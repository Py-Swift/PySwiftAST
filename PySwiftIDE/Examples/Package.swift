// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "BasicUsageExample",
    platforms: [.macOS(.v14)],
    dependencies: [
        .package(path: "../")
    ],
    targets: [
        .executableTarget(
            name: "BasicUsageExample",
            dependencies: [
                .product(name: "PySwiftIDE", package: "PySwiftIDE"),
                .product(name: "MonacoApi", package: "PySwiftIDE")
            ],
            path: ".",
            sources: ["BasicUsage.swift"]
        )
    ]
)
