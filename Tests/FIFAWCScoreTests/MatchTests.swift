import XCTest
@testable import FIFAWCSCORES

final class MatchTests: XCTestCase {

    // MARK: - Helpers

    private func makeMatch(
        status: MatchStatus = .scheduled,
        homeScore: Int? = nil,
        awayScore: Int? = nil,
        group: String? = "GROUP_A",
        stage: String? = nil
    ) -> Match {
        Match(
            id: 1,
            utcDate: Date(),
            status: status,
            matchday: 1,
            stage: stage,
            group: group,
            homeTeam: Team(id: 1, name: "Brazil", shortName: "Brazil", tla: "BRA", crest: nil),
            awayTeam: Team(id: 2, name: "Argentina", shortName: "Argentina", tla: "ARG", crest: nil),
            score: Score(
                winner: nil,
                duration: "REGULAR",
                fullTime: ScoreValues(home: homeScore, away: awayScore),
                halfTime: ScoreValues(home: nil, away: nil)
            ),
            venue: "MetLife Stadium"
        )
    }

    // MARK: - Computed Properties

    func testHomeScore() {
        let match = makeMatch(homeScore: 3, awayScore: 1)
        XCTAssertEqual(match.homeScore, 3)
    }

    func testAwayScore() {
        let match = makeMatch(homeScore: 3, awayScore: 1)
        XCTAssertEqual(match.awayScore, 1)
    }

    func testNilScores() {
        let match = makeMatch(homeScore: nil, awayScore: nil)
        XCTAssertNil(match.homeScore)
        XCTAssertNil(match.awayScore)
    }

    func testIsLive() {
        XCTAssertTrue(makeMatch(status: .inPlay).isLive)
        XCTAssertTrue(makeMatch(status: .paused).isLive)
        XCTAssertFalse(makeMatch(status: .scheduled).isLive)
        XCTAssertFalse(makeMatch(status: .finished).isLive)
    }

    func testIsFinished() {
        XCTAssertTrue(makeMatch(status: .finished).isFinished)
        XCTAssertFalse(makeMatch(status: .inPlay).isFinished)
        XCTAssertFalse(makeMatch(status: .scheduled).isFinished)
    }

    func testDisplayTextLive() {
        let match = makeMatch(status: .inPlay, homeScore: 2, awayScore: 1)
        XCTAssertEqual(match.displayText, "2 - 1")
    }

    func testDisplayTextPaused() {
        let match = makeMatch(status: .paused, homeScore: 0, awayScore: 0)
        XCTAssertEqual(match.displayText, "0 - 0")
    }

    func testDisplayTextFinished() {
        let match = makeMatch(status: .finished, homeScore: 3, awayScore: 2)
        XCTAssertEqual(match.displayText, "3 - 2")
    }

    func testDisplayTextScheduledShowsTime() {
        // Use a future date so effectiveStatus stays .scheduled (not inferred as .inPlay)
        let futureDate = Date().addingTimeInterval(3600 * 5)
        let match = Match(
            id: 1, utcDate: futureDate, status: .scheduled, matchday: 1,
            stage: nil, group: "GROUP_A",
            homeTeam: Team(id: 1, name: "Brazil", shortName: "Brazil", tla: "BRA", crest: nil),
            awayTeam: Team(id: 2, name: "Argentina", shortName: "Argentina", tla: "ARG", crest: nil),
            score: Score(winner: nil, duration: "REGULAR",
                fullTime: ScoreValues(home: nil, away: nil),
                halfTime: ScoreValues(home: nil, away: nil)),
            venue: "MetLife Stadium"
        )
        // Should return a time string (e.g. "3:00 PM"), not a score
        XCTAssertFalse(match.displayText.contains(" - "))
    }

    func testGroupDisplay() {
        let match = makeMatch(group: "GROUP_A")
        XCTAssertEqual(match.groupDisplay, "Group A")
    }

    func testGroupDisplayFromStage() {
        let match = makeMatch(group: nil, stage: "FINAL")
        XCTAssertEqual(match.groupDisplay, "Final")
    }

    func testGroupDisplayNil() {
        let match = makeMatch(group: nil, stage: nil)
        XCTAssertNil(match.groupDisplay)
    }

    // MARK: - Codable Round-Trip

    func testCodableRoundTrip() throws {
        let json = """
        {
            "id": 42,
            "utcDate": "2026-06-15T20:00:00Z",
            "status": "IN_PLAY",
            "matchday": 1,
            "stage": "GROUP_STAGE",
            "group": "GROUP_A",
            "homeTeam": {"id": 1, "name": "Brazil", "shortName": "Brazil", "tla": "BRA", "crest": null},
            "awayTeam": {"id": 2, "name": "Argentina", "shortName": "Argentina", "tla": "ARG", "crest": null},
            "score": {"winner": null, "duration": "REGULAR", "fullTime": {"home": 2, "away": 1}, "halfTime": {"home": 1, "away": 0}},
            "venue": "MetLife Stadium"
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601

        let match = try decoder.decode(Match.self, from: json)

        XCTAssertEqual(match.id, 42)
        XCTAssertEqual(match.status, .inPlay)
        XCTAssertEqual(match.homeTeam.tla, "BRA")
        XCTAssertEqual(match.awayTeam.tla, "ARG")
        XCTAssertEqual(match.homeScore, 2)
        XCTAssertEqual(match.awayScore, 1)
        XCTAssertEqual(match.group, "GROUP_A")
        XCTAssertTrue(match.isLive)

        // Encode back
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        encoder.dateEncodingStrategy = .iso8601
        let encoded = try encoder.encode(match)
        let decoded = try decoder.decode(Match.self, from: encoded)

        XCTAssertEqual(decoded.id, match.id)
        XCTAssertEqual(decoded.status, match.status)
        XCTAssertEqual(decoded.homeScore, match.homeScore)
    }
}
