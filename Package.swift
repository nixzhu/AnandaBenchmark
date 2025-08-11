// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "AnandaBenchmark",
    platforms: [
        .macOS(.v14),
    ],
    dependencies: [
        .package(
            url: "https://github.com/nixzhu/Ananda.git",
            from: "1.1.0"
        ),
        .package(
            url: "https://github.com/nixzhu/AnandaMacros.git",
            from: "1.2.0"
        ),
        .package(
            url: "https://github.com/SwiftyJSON/SwiftyJSON.git",
            from: "5.0.2"
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
                    name: "AnandaMacros",
                    package: "AnandaMacros"
                ),
                .product(
                    name: "SwiftyJSON",
                    package: "SwiftyJSON"
                ),
                .product(
                    name: "Benchmark",
                    package: "swift-benchmark"
                ),
            ],
            resources: [
                .copy("github_events.json"),
            ]
        ),
    ]
)
