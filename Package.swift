// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "AnandaBenchmark",
    platforms: [
        .macOS(.v13),
    ],
    dependencies: [
        .package(
            url: "https://github.com/nixzhu/Ananda.git",
            from: "0.5.0"
        ),
        .package(
            url: "https://github.com/google/swift-benchmark.git",
            from: "0.1.2"
        ),
    ],
    targets: [
        .executableTarget(
            name: "AnandaBenchmark",
            dependencies: [
                .product(
                    name: "Ananda",
                    package: "Ananda"
                ),
                .product(
                    name: "Benchmark",
                    package: "swift-benchmark"
                ),
            ]
        ),
    ]
)
