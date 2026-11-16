import AppKit
import Combine

// App Store build: updates come from the Mac App Store, so this module keeps the
// same public surface as the Sparkle-based updater but never checks, downloads or installs.

public enum GitHubRepositoryError: Error { case invalid }

public struct GitHubRepository: Equatable, Codable, Sendable {
    public let slug: String
    public var websiteURL: URL { URL(string: "https://github.com/\(slug)")! }
    public init(_ input: String) throws {
        let value = input.trimmingCharacters(in: .whitespacesAndNewlines)
        let parts = value.split(separator: "/")
        guard parts.count == 2 else { throw GitHubRepositoryError.invalid }
        slug = value
    }
}

@MainActor public final class AppUpdater: NSObject, ObservableObject {
    @Published public private(set) var availableVersion: String?
    @Published public private(set) var configurationError: String?
    @Published public private(set) var lastError: String?
    @Published public private(set) var canCheckForUpdates = false
    @Published public private(set) var automaticallyChecksForUpdates = false
    @Published public private(set) var lastCheckedAt: Date?
    @Published public private(set) var sessionInProgress = false
    @Published public private(set) var waitingForCurrentTask = false
    @Published public private(set) var isBusy = false
    @Published public private(set) var repository: GitHubRepository?
    @Published public private(set) var requiresToken = false
    @Published public private(set) var hasSavedToken = false
    @Published public private(set) var isConnecting = false
    @Published public private(set) var isPreparingCheck = false

    public var officialRepository: GitHubRepository? { nil }
    public var isConfigured: Bool { false }
    public var canChangeConnection: Bool { false }

    public override init() { super.init() }
    public func start() {}
    public func checkForUpdates() {}
    public func setAutomaticChecks(_ enabled: Bool) {}
    public func setBusy(_ busy: Bool) { isBusy = busy }
    public func connectGitHub(repository input: String, token inputToken: String, requiresToken: Bool) async throws { throw GitHubRepositoryError.invalid }
    public func disconnectGitHub() async throws {}
}
