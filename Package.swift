// swift-tools-version: 6.0
import PackageDescription
import Foundation

// MALKH_APPSTORE=1 builds the Mac App Store edition: sandbox-friendly, no Sparkle,
// no downloaded tools, no web downloads and no window management (see #if APPSTORE).
let appStore = ProcessInfo.processInfo.environment["MALKH_APPSTORE"] == "1"
let settings: [SwiftSetting] = appStore ? [.define("APPSTORE")] : []

let updatesTarget: Target = appStore
    ? .target(name: "MalkhUpdates", path: "Sources/MalkhUpdatesAppStore", swiftSettings: settings)
    // The frozen XPC wire protocol stays at its sealed source path. It is compiled
    // into the renamed module without changing its Objective-C identity.
    : .target(name: "MalkhUpdates", dependencies: [.product(name: "Sparkle", package: "Sparkle")], path: "Sources",
              exclude: ["MalkhApp", "MalkhCore", "MalkhCLI", "UpdateCredentialBroker", "MalkhUpdatesAppStore"],
              sources: ["MalkhUpdates", "MalkhUpdateProtocol/UpdateCredentialBrokerProtocol.swift"])

var targets: [Target] = [
    .target(name: "MalkhCore", resources: [.copy("Resources")], swiftSettings: settings),
    updatesTarget,
    .executableTarget(name: "MalkhApp", dependencies: ["MalkhCore", "MalkhUpdates"], swiftSettings: settings,
                      linkerSettings: [.unsafeFlags(["-Xlinker", "-rpath", "-Xlinker", "@executable_path/../Frameworks"])]),
    .executableTarget(name: "MalkhCLI", dependencies: ["MalkhCore"], swiftSettings: settings),
]
if !appStore {
    targets += [
        .testTarget(name: "MalkhCoreTests", dependencies: ["MalkhCore"], resources: [.copy("Fixtures")]),
        .testTarget(name: "MalkhUpdatesTests", dependencies: ["MalkhUpdates"]),
    ]
}

let package = Package(
    name: "Malkh",
    platforms: [.macOS(.v13)],
    products: [
        .library(name: "MalkhCore", targets: ["MalkhCore"]),
        .executable(name: "Malkh", targets: ["MalkhApp"]),
        .executable(name: "malkh-cli", targets: ["MalkhCLI"])
    ],
    dependencies: appStore ? [] : [
        .package(url: "https://github.com/sparkle-project/Sparkle", exact: "2.10.0")
    ],
    targets: targets,
    swiftLanguageModes: [.v5]
)
