// swift-tools-version:5.7
import PackageDescription

let package = Package(
    name: "Cinderella",
    platforms: [.macOS(.v12)],
    products: [
        .executable(name: "Cinderella", targets: ["Cinderella"]),
    ],
    targets: [
        .executableTarget(
            name: "Cinderella",
            path: "Sources/Cinderella",
            resources: [.process("Resources")]
        ),
        .testTarget(
            name: "CinderellaTests",
            dependencies: ["Cinderella"],
            path: "Tests"
        )
    ]
)
