// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "icfpworker",
    products: [
        .library(
            name: "ICFPWorkerLib",
            targets: ["ICFPWorkerLib"]
        ),
        .executable(
            name: "icfpworker",
            targets: ["ICFPWorkerCLI"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.3.0")
    ],
    targets: [
        .target(
            name: "ICFPWorkerLib",
            dependencies: []
        ),
        .executableTarget(
            name: "ICFPWorkerCLI",
            dependencies: [
                "ICFPWorkerLib",
                .product(name: "ArgumentParser", package: "swift-argument-parser")
            ]
        ),
        .testTarget(
            name: "ICFPWorkerLibTests",
            dependencies: ["ICFPWorkerLib"]
        ),
    ]
)