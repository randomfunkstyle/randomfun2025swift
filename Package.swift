// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "icfpworker",
    platforms: [
        .macOS(.v12)
    ],
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
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.3.0"),
        .package(url: "https://github.com/BrokenHandsIO/Accelerate-Linux.git", branch: "main"),
    ],
    targets: [
        .target(
            name: "ICFPWorkerLib",
            dependencies: [
                .product(
                    name: "AccelerateLinux", package: "Accelerate-Linux",
                    condition: .when(platforms: [.linux]))
            ]
        ),
        .executableTarget(
            name: "ICFPWorkerCLI",
            dependencies: [
                "ICFPWorkerLib",
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ]
        ),
        .testTarget(
            name: "ICFPWorkerLibTests",
            dependencies: ["ICFPWorkerLib"]
        ),
    ]
)
