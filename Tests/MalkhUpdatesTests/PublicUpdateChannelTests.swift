import XCTest
@testable import MalkhUpdates

final class PublicUpdateChannelTests:XCTestCase {
    private let info:[String:Any]=["MalkhPublicUpdateRepository":"nurali/malkh","SUFeedURL":"https://github.com/nurali/malkh/releases/latest/download/appcast.xml"]
    private final class NoCredentials:UpdateCredentialStore,@unchecked Sendable {
        func token(for repository:GitHubRepository) throws->String { XCTFail("Anonymous migration read a private token");throw UpdateCredentialError.missing }
        func save(_ token:String,for repository:GitHubRepository) throws { XCTFail("Anonymous migration wrote a credential") }
        func remove(for repository:GitHubRepository) throws { XCTFail("Anonymous migration deleted a credential") }
    }
    func testOfficialChannelRequiresExactBundledFeed() {
        XCTAssertNotNil(PublicUpdateChannel(info:info))
        for address in ["http://github.com/nurali/malkh/releases/latest/download/appcast.xml","https://github.com/attacker/malkh-app/releases/latest/download/appcast.xml","https://github.com/nurali/malkh/releases/latest/download/appcast.xml?token=x"] {
            var altered=info;altered["SUFeedURL"]=address;XCTAssertNil(PublicUpdateChannel(info:altered))
        }
    }
    func testNewUsersAndLegacyUsersDoNotTouchCredentials() async {
        for previous in [nil,"nurali/malkh","nurali/malkh","nurali/malkh"] as [String?] {
            let suite="MalkhPublicChannelTests.\(UUID())",defaults=UserDefaults(suiteName:suite)!
            defer { defaults.removePersistentDomain(forName:suite) }
            if let previous { defaults.set(previous,forKey:"MalkhUpdateGitHubRepository");defaults.set(true,forKey:"MalkhUpdateGitHubRequiresToken");defaults.set(true,forKey:"MalkhUpdateGitHubSavedToken") }
            defaults.set("retained",forKey:"history");defaults.set(false,forKey:"MalkhUpdateGitHubAutomaticChecks")
            await MainActor.run {
                let updater=AppUpdater(credentials:NoCredentials(),defaults:defaults,info:info)
                XCTAssertNil(updater.repository);XCTAssertFalse(updater.requiresToken);XCTAssertFalse(updater.hasSavedToken)
                XCTAssertEqual(updater.officialRepository?.slug,"nurali/malkh")
            }
            XCTAssertEqual(defaults.string(forKey:"history"),"retained")
            if previous != nil { XCTAssertEqual(defaults.object(forKey:"SUEnableAutomaticChecks") as? Bool,false) }
        }
    }
    func testUnrelatedCustomChannelIsPreserved() async {
        let suite="MalkhPublicChannelTests.\(UUID())",defaults=UserDefaults(suiteName:suite)!
        defer { defaults.removePersistentDomain(forName:suite) }
        defaults.set("example/custom",forKey:"MalkhUpdateGitHubRepository");defaults.set(true,forKey:"MalkhUpdateGitHubRequiresToken")
        await MainActor.run {
            let updater=AppUpdater(credentials:NoCredentials(),defaults:defaults,info:info)
            XCTAssertEqual(updater.repository?.slug,"example/custom");XCTAssertTrue(updater.requiresToken)
        }
    }
}
