import XCTest
@testable import MalkhUpdates

final class BrandMigrationTests:XCTestCase {
    private final class UnusedCredentials:UpdateCredentialStore,@unchecked Sendable {
        var reads=0
        func token(for repository:GitHubRepository) throws->String { reads += 1;throw UpdateCredentialError.missing }
        func save(_ token:String,for repository:GitHubRepository) throws { XCTFail("A rename must not save or replace credentials") }
        func remove(for repository:GitHubRepository) throws { XCTFail("A rename must not delete credentials") }
    }
    func testSavedConnectionIsRenamedWithoutTouchingSecretsOrPreferences() async throws {
        let suite="MalkhBrandMigrationTests.\(UUID())"
        let defaults=UserDefaults(suiteName:suite)!
        defer { defaults.removePersistentDomain(forName:suite) }
        defaults.set("busulbman/malkh",forKey:"MalkhUpdateGitHubRepository")
        defaults.set(true,forKey:"MalkhUpdateGitHubSavedToken")
        defaults.set(true,forKey:"MalkhUpdateGitHubRequiresToken")
        defaults.set(false,forKey:"MalkhUpdateGitHubAutomaticChecks")
        defaults.set("preserved history",forKey:"history")
        let store=UnusedCredentials()
        let updater=await MainActor.run { AppUpdater(credentials:store,defaults:defaults) }
        await MainActor.run { XCTAssertEqual(updater.repository?.slug,"busulbman/malkh");XCTAssertTrue(updater.hasSavedToken);XCTAssertTrue(updater.requiresToken) }
        XCTAssertEqual(defaults.string(forKey:"MalkhUpdateGitHubRepository"),"busulbman/malkh")
        XCTAssertFalse(defaults.bool(forKey:"MalkhUpdateGitHubAutomaticChecks"));XCTAssertEqual(defaults.string(forKey:"history"),"preserved history");XCTAssertEqual(store.reads,0)
    }
    func testRepositoryRenameUsesOnlyTheExistingCredentialAccount() throws {
        XCTAssertEqual(UpdateBrandMigration.credentialAccount(UpdateBrandMigration.current),UpdateBrandMigration.previous)
        let unrelated=try GitHubRepository("example/malkh")
        XCTAssertEqual(UpdateBrandMigration.credentialAccount(unrelated),unrelated)
        XCTAssertEqual(UpdateBrandMigration.canonical(unrelated),unrelated)
    }
    func testOldSignedArchiveURLsAreAcceptedOnlyForThisRename() throws {
        let url=URL(string:"https://github.com/busulbman/malkh/releases/download/v0.6.0-24/Malkh-0.6.0-24.zip")!
        let current=GitHubUpdateClient(repository:UpdateBrandMigration.current,token:nil)
        XCTAssertEqual(try current.archiveReference(for:url),.release(tag:"v0.6.0-24",filename:"Malkh-0.6.0-24.zip"))
        for slug in ["other/malkh","busulbman/unrelated"] {
            let unrelated=GitHubUpdateClient(repository:try GitHubRepository(slug),token:nil)
            XCTAssertThrowsError(try unrelated.archiveReference(for:url))
        }
        XCTAssertThrowsError(try current.archiveReference(for:URL(string:"https://github.com/other/malkh/releases/download/v1/a.zip")!))
    }
}
