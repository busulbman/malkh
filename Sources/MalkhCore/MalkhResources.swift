import Foundation

/// Finds MalkhCore's bundled files without SwiftPM's `Bundle.module`, which falls back to the
/// absolute build directory and traps when the app runs on another Mac or inside the App Store sandbox.
/// Never traps: a missing file returns nil and the UI stays in English.
enum MalkhResources {
    private static let bundleName = "Malkh_MalkhCore.bundle"
    private static let roots: [URL] = {
        var bases: [URL] = []
        if let resources = Bundle.main.resourceURL { bases.append(resources.appendingPathComponent(bundleName)) }
        bases.append(Bundle.main.bundleURL.appendingPathComponent(bundleName))
        if let executable = Bundle.main.executableURL { bases.append(executable.deletingLastPathComponent().appendingPathComponent(bundleName)) }
        // Flat SwiftPM layout (GitHub build, swift run) and standard macOS layout (App Store build).
        return bases.flatMap { [$0.appendingPathComponent("Resources"), $0.appendingPathComponent("Contents/Resources/Resources")] }
    }()
    static func url(_ name: String, _ ext: String) -> URL? {
        for root in roots {
            let file = root.appendingPathComponent(name).appendingPathExtension(ext)
            if FileManager.default.isReadableFile(atPath: file.path) { return file }
        }
        return nil
    }
}
