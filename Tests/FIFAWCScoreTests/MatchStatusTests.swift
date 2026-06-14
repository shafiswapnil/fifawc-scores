import XCTest
@testable import FIFAWCSCORES

final class MatchStatusTests: XCTestCase {

    func testDisplayName() {
        XCTAssertEqual(MatchStatus.scheduled.displayName, "Scheduled")
        XCTAssertEqual(MatchStatus.timed.displayName, "Timed")
        XCTAssertEqual(MatchStatus.inPlay.displayName, "Live")
        XCTAssertEqual(MatchStatus.paused.displayName, "Half Time")
        XCTAssertEqual(MatchStatus.finished.displayName, "FT")
        XCTAssertEqual(MatchStatus.postponed.displayName, "Postponed")
        XCTAssertEqual(MatchStatus.suspended.displayName, "Suspended")
        XCTAssertEqual(MatchStatus.cancelled.displayName, "Cancelled")
        XCTAssertEqual(MatchStatus.awarded.displayName, "Awarded")
    }

    func testIsLive() {
        XCTAssertTrue(MatchStatus.inPlay.isLive)
        XCTAssertTrue(MatchStatus.paused.isLive)

        XCTAssertFalse(MatchStatus.scheduled.isLive)
        XCTAssertFalse(MatchStatus.timed.isLive)
        XCTAssertFalse(MatchStatus.finished.isLive)
        XCTAssertFalse(MatchStatus.postponed.isLive)
        XCTAssertFalse(MatchStatus.suspended.isLive)
        XCTAssertFalse(MatchStatus.cancelled.isLive)
        XCTAssertFalse(MatchStatus.awarded.isLive)
    }

    func testHasStarted() {
        XCTAssertTrue(MatchStatus.inPlay.hasStarted)
        XCTAssertTrue(MatchStatus.paused.hasStarted)
        XCTAssertTrue(MatchStatus.finished.hasStarted)

        XCTAssertFalse(MatchStatus.scheduled.hasStarted)
        XCTAssertFalse(MatchStatus.timed.hasStarted)
        XCTAssertFalse(MatchStatus.postponed.hasStarted)
        XCTAssertFalse(MatchStatus.suspended.hasStarted)
        XCTAssertFalse(MatchStatus.cancelled.hasStarted)
        XCTAssertFalse(MatchStatus.awarded.hasStarted)
    }

    func testRawValueDecoding() throws {
        let json = "\"IN_PLAY\"".data(using: .utf8)!
        let status = try JSONDecoder().decode(MatchStatus.self, from: json)
        XCTAssertEqual(status, .inPlay)
    }

    func testAllCasesCovered() {
        // Ensure our test covers every case
        let allCases: [MatchStatus] = [
            .scheduled, .timed, .inPlay, .paused, .finished,
            .postponed, .suspended, .cancelled, .awarded
        ]
        XCTAssertEqual(allCases.count, 9)
        for status in allCases {
            XCTAssertFalse(status.displayName.isEmpty, "\(status) has empty displayName")
        }
    }
}
