// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Malkh",
    platforms: [.macOS(.v13)],
    products: [
        .library(name: "MalkhCore", targets: ["MalkhCore"]),
        .executable(name: "Malkh", targets: ["MalkhApp"]),
        .executable(name: "malkh-cli", targets: ["MalkhCLI"])
    ],
    dependencies: [
        .package(url: "https://github.com/sparkle-project/Sparkle", exact: "2.10.0")
    ],
    targets: [
        .target(name: "MalkhCore", resources: [.copy("Resources")]),
        // The frozen XPC wire protocol stays at its sealed source path. It is compiled
        // into the renamed module without changing its Objective-C identity.
        .target(name: "MalkhUpdates", dependencies: [.product(name: "Sparkle", package: "Sparkle")], path: "Sources", exclude: ["MalkhApp", "MalkhCore", "MalkhCLI", "UpdateCredentialBroker"], sources: ["MalkhUpdates", "MalkhUpdateProtocol/UpdateCredentialBrokerProtocol.swift"]),
        .executableTarget(name: "MalkhApp", dependencies: ["MalkhCore", "MalkhUpdates"], linkerSettings: [.unsafeFlags(["-Xlinker", "-rpath", "-Xlinker", "@executable_path/../Frameworks"])]),
        .executableTarget(name: "MalkhCLI", dependencies: ["MalkhCore"]),
        .testTarget(name: "MalkhCoreTests", dependencies: ["MalkhCore"], resources: [.copy("Fixtures")]),
        .testTarget(name: "MalkhUpdatesTests", dependencies: ["MalkhUpdates"])
    ],
    swiftLanguageModes: [.v5]
)
