import XCTest
@testable import FIFAWCSCORES

final class TeamTests: XCTestCase {

    func testFlagEmojiKnown() {
        let team = Team(id: 1, name: "Brazil", shortName: "Brazil", tla: "BRA", crest: nil)
        XCTAssertEqual(team.flagEmoji, "🇧🇷")
    }

    func testFlagEmojiUnknown() {
        let team = Team(id: 99, name: "Atlantis", shortName: "Atlantis", tla: "ATL", crest: nil)
        XCTAssertEqual(team.flagEmoji, "🏳️")
    }

    func testAllTLAsHaveFlags() {
        // Every key in TeamFlags.flags should map to an emoji
        for (tla, emoji) in TeamFlags.flags {
            XCTAssertFalse(emoji.isEmpty, "TLA '\(tla)' has empty flag emoji")
        }
    }

    func testNoDuplicateTLAs() {
        // Verify unique count matches total count (would fail if Swift let duplicate keys compile)
        let keys = Array(TeamFlags.flags.keys)
        let uniqueKeys = Set(keys)
        XCTAssertEqual(keys.count, uniqueKeys.count, "Duplicate TLAs detected in TeamFlags.flags")
    }

    func testCodableRoundTrip() throws {
        let team = Team(id: 1, name: "Germany", shortName: "Germany", tla: "GER", crest: "https://example.com/ger.png")
        let data = try JSONEncoder().encode(team)
        let decoded = try JSONDecoder().decode(Team.self, from: data)

        XCTAssertEqual(decoded.id, team.id)
        XCTAssertEqual(decoded.name, team.name)
        XCTAssertEqual(decoded.tla, team.tla)
        XCTAssertEqual(decoded.crest, team.crest)
        XCTAssertEqual(decoded.flagEmoji, "🇩🇪")
    }
}
