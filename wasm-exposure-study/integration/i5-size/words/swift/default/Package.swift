// swift-tools-version:6.0
import PackageDescription

let package = Package(
    name: "App",
    targets: [
        .executableTarget(
            name: "App",
            path: "Sources/App",
            swiftSettings: [.enableExperimentalFeature("Extern")]
        )
    ]
)
