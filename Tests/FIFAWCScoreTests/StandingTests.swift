import XCTest
@testable import FIFAWCSCORES

final class StandingTests: XCTestCase {

    // MARK: - Helpers

    private func makeEntry(position: Int = 1, won: Int = 2, draw: Int = 1, lost: Int = 0, gd: Int = 5) -> StandingEntry {
        StandingEntry(
            position: position,
            team: Team(id: 1, name: "Brazil", shortName: "Brazil", tla: "BRA", crest: nil),
            playedGames: won + draw + lost,
            won: won,
            draw: draw,
            lost: lost,
            points: won * 3 + draw,
            goalsFor: gd + 3,
            goalsAgainst: 3,
            goalDifference: gd,
            form: nil
        )
    }

    // MARK: - StandingEntry

    func testIsQualified() {
        XCTAssertTrue(makeEntry(position: 1).isQualified)
        XCTAssertTrue(makeEntry(position: 2).isQualified)
        XCTAssertFalse(makeEntry(position: 3).isQualified)
        XCTAssertFalse(makeEntry(position: 4).isQualified)
    }

    func testGoalDifferencePositive() {
        let entry = makeEntry(gd: 7)
        XCTAssertEqual(entry.goalDifferenceText, "+7")
    }

    func testGoalDifferenceNegative() {
        let entry = makeEntry(gd: -3)
        XCTAssertEqual(entry.goalDifferenceText, "-3")
    }

    func testGoalDifferenceZero() {
        let entry = makeEntry(gd: 0)
        XCTAssertEqual(entry.goalDifferenceText, "0")
    }

    func testIdIsTeamTLA() {
        let entry = makeEntry()
        XCTAssertEqual(entry.id, "BRA")
    }

    // MARK: - GroupStanding

    func testDisplayName() {
        let group = GroupStanding(
            stage: "GROUP_STAGE",
            type: "TOTAL",
            group: "GROUP_A",
            table: []
        )
        XCTAssertEqual(group.displayName, "Group A")
    }

    func testIdIsGroupName() {
        let group = GroupStanding(
            stage: nil,
            type: nil,
            group: "GROUP_H",
            table: []
        )
        XCTAssertEqual(group.id, "GROUP_H")
    }

    func testCodableRoundTrip() throws {
        let entry = makeEntry(position: 1, won: 3, draw: 0, lost: 0, gd: 8)
        let group = GroupStanding(
            stage: "GROUP_STAGE",
            type: "TOTAL",
            group: "GROUP_B",
            table: [entry]
        )

        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        let data = try encoder.encode(group)

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let decoded = try decoder.decode(GroupStanding.self, from: data)

        XCTAssertEqual(decoded.group, "GROUP_B")
        XCTAssertEqual(decoded.table.count, 1)
        XCTAssertEqual(decoded.table.first?.position, 1)
        XCTAssertEqual(decoded.table.first?.points, 9)
    }
}
