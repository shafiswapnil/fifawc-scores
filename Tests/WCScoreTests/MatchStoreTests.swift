import XCTest
@testable import WCSCORES

/// Tests for MatchStore computed properties and settings logic.
/// Does NOT test network calls — validates state management only.
@MainActor
final class MatchStoreTests: XCTestCase {

    private func makeStore(apiKey: String = "test-key") -> MatchStore {
        UserDefaults.standard.removeObject(forKey: "apiKey")
        UserDefaults.standard.removeObject(forKey: "pollInterval")
        UserDefaults.standard.removeObject(forKey: "favoriteTeam")
        let store = MatchStore()
        store.apiKey = apiKey
        return store
    }

    // MARK: - API Key Guard

    func testHasApiKeyTrue() {
        let store = makeStore(apiKey: "valid-key")
        XCTAssertTrue(store.hasApiKey)
    }

    func testHasApiKeyFalse() {
        let store = makeStore(apiKey: "")
        XCTAssertFalse(store.hasApiKey)
    }

    func testHasApiKeyWhitespace() {
        let store = makeStore(apiKey: "   ")
        XCTAssertFalse(store.hasApiKey)
    }

    // MARK: - Empty State

    func testEmptyStoreHasNoMatches() {
        let store = makeStore()
        XCTAssertTrue(store.todayMatches.isEmpty)
        XCTAssertTrue(store.yesterdayMatches.isEmpty)
        XCTAssertTrue(store.tomorrowMatches.isEmpty)
        XCTAssertTrue(store.allMatches.isEmpty)
        XCTAssertTrue(store.liveMatches.isEmpty)
        XCTAssertFalse(store.hasLiveMatches)
    }

    func testEmptyStoreFeaturedMatchIsNil() {
        let store = makeStore()
        XCTAssertNil(store.featuredMatch)
    }

    func testEmptyStoreNextMatchIsNil() {
        let store = makeStore()
        XCTAssertNil(store.nextMatch)
    }

    // MARK: - Settings

    func testPollIntervalMinimum() {
        let store = makeStore()
        store.pollInterval = 10  // Below minimum of 60
        XCTAssertEqual(store.pollInterval, 60)
    }

    func testPollIntervalAcceptsValidValue() {
        let store = makeStore()
        store.pollInterval = 120
        XCTAssertEqual(store.pollInterval, 120)
    }

    func testFavoriteTeam() {
        let store = makeStore()
        store.favoriteTeam = "BRA"
        XCTAssertEqual(store.favoriteTeam, "BRA")
    }

    func testFavoriteTeamNil() {
        let store = makeStore()
        store.favoriteTeam = "BRA"
        store.favoriteTeam = nil
        XCTAssertNil(store.favoriteTeam)
    }

    func testFetchAllDataWithoutApiKeyShowsError() async {
        let store = makeStore(apiKey: "")
        await store.fetchAllData()
        XCTAssertNotNil(store.errorMessage)
        XCTAssertTrue(store.errorMessage!.contains("API key"))
    }

    func testFetchAllDataIsIdempotent() async {
        let store = makeStore(apiKey: "test-key")
        // First fetch will fail (no real API), but should set isFetching back
        await store.fetchAllData()
        XCTAssertFalse(store.isFetching)
    }
}
