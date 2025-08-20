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
        // Add any external dependencies here
    ],
    targets: [
        .target(
            name: "ICFPWorkerLib",
            dependencies: []
        ),
        .executableTarget(
            name: "ICFPWorkerCLI",
            dependencies: ["ICFPWorkerLib"]
        ),
        .testTarget(
            name: "ICFPWorkerLibTests",
            dependencies: ["ICFPWorkerLib"]
        ),
    ]
)