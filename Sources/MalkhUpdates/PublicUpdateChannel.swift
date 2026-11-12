import Foundation

/// The official anonymous channel is fixed in the signed bundle. A remote feed
/// cannot select a repository or ask this app to load a saved GitHub credential.
public struct PublicUpdateChannel:Equatable {
    public let repository:GitHubRepository
    public init?(info:[String:Any]) {
        guard let slug=info["MalkhPublicUpdateRepository"] as? String,
              let repository=try? GitHubRepository(slug),
              info["SUFeedURL"] as? String == repository.websiteURL.appendingPathComponent("releases/latest/download/appcast.xml").absoluteString else { return nil }
        self.repository=repository
    }

    /// Migrate the project's two legacy private channels without reading or
    /// deleting their Keychain items. Unrelated custom channels are preserved.
    public func migrate(_ defaults:UserDefaults) {
        let key="MalkhUpdateGitHubRepository"
        guard let saved=defaults.string(forKey:key),
              ["nurali/malkh","nurali/malkh",repository.slug].contains(saved.lowercased()) else { return }
        if saved.lowercased() != repository.slug {
            defaults.set(saved,forKey:"MalkhPreviousUpdateRepository")
        }
        for name in [key,"MalkhUpdateGitHubRequiresToken","MalkhUpdateGitHubSavedToken"] { defaults.removeObject(forKey:name) }
        if let automatic=defaults.object(forKey:"MalkhUpdateGitHubAutomaticChecks") as? Bool {
            defaults.set(automatic,forKey:"SUEnableAutomaticChecks")
        }
        defaults.set(repository.slug,forKey:"MalkhPublicChannelMigration")
    }
}
