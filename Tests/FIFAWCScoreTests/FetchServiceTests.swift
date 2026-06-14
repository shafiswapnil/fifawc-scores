import XCTest
@testable import FIFAWCSCORES

/// Tests for FetchService URL construction, rate limiting, and error handling.
/// Does NOT make real network calls — validates internal logic only.
/// The actor isolation is handled by calling through the async API.
final class FetchServiceTests: XCTestCase {

    // MARK: - API Key

    func testHasApiKeyTrue() async {
        let service = FetchService(apiKey: "test-key-123")
        let hasKey = await service.hasApiKey
        XCTAssertTrue(hasKey)
    }

    func testHasApiKeyFalse() async {
        let service = FetchService(apiKey: "")
        let hasKey = await service.hasApiKey
        XCTAssertFalse(hasKey)
    }

    func testHasApiKeyPlaceholder() async {
        let service = FetchService(apiKey: "REPLACE_WITH_YOUR_API_KEY")
        let hasKey = await service.hasApiKey
        XCTAssertFalse(hasKey)
    }

    func testUpdateApiKey() async {
        let service = FetchService(apiKey: "")
        var hasKey = await service.hasApiKey
        XCTAssertFalse(hasKey)

        await service.updateApiKey("new-key")
        hasKey = await service.hasApiKey
        XCTAssertTrue(hasKey)
    }

    // MARK: - Error Descriptions

    func testFetchErrorDescriptions() {
        XCTAssertEqual(FetchError.invalidURL.errorDescription, "Invalid URL")
        XCTAssertEqual(FetchError.invalidAPIKey.errorDescription, "No API key — set one in Settings")
        XCTAssertEqual(FetchError.rateLimited.errorDescription, "Rate limited — too many requests")
        XCTAssertEqual(FetchError.noData.errorDescription, "No data received")
        XCTAssertEqual(FetchError.serverError(500).errorDescription, "Server error (500)")
    }

    func testNetworkErrorWrapsUnderlyingError() {
        let underlying = NSError(domain: "test", code: 42, userInfo: nil)
        let error = FetchError.networkError(underlying)
        XCTAssertTrue(error.errorDescription!.contains("42"))
    }

    func testDecodingErrorWrapsUnderlyingError() {
        let underlying = NSError(domain: "test", code: 99, userInfo: nil)
        let error = FetchError.decodingError(underlying)
        XCTAssertTrue(error.errorDescription!.contains("99"))
    }

    // MARK: - Invalid API Key Short-Circuits

    func testFetchMatchesWithEmptyKeyThrows() async {
        let service = FetchService(apiKey: "")
        do {
            _ = try await service.fetchMatches(for: Date())
            XCTFail("Expected invalidAPIKey error")
        } catch {
            XCTAssertTrue(error is FetchError)
            XCTAssertEqual(error as? FetchError, .invalidAPIKey)
        }
    }

    func testFetchStandingsWithEmptyKeyThrows() async {
        let service = FetchService(apiKey: "")
        do {
            _ = try await service.fetchStandings()
            XCTFail("Expected invalidAPIKey error")
        } catch {
            XCTAssertEqual(error as? FetchError, .invalidAPIKey)
        }
    }
}
