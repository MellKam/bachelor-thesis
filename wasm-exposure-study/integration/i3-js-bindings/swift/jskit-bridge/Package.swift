// swift-tools-version:6.2
import PackageDescription

let package = Package(
    name: "App",
    dependencies: [.package(url: "https://github.com/swiftwasm/JavaScriptKit", exact: "0.59.0")],
    targets: [
        .executableTarget(
            name: "App",
            dependencies: [.product(name: "JavaScriptKit", package: "JavaScriptKit")],
            path: "Sources/App"
        )
    ]
)
