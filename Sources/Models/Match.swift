import Foundation

/// A FIFA World Cup match with scores, status, and metadata.
struct Match: Codable, Sendable, Identifiable {
    let id: Int
    let utcDate: Date
    let status: MatchStatus
    let matchday: Int?
    let stage: String?
    let group: String?
    let homeTeam: Team
    let awayTeam: Team
    let score: Score
    let venue: String?

    /// Home team's current score.
    var homeScore: Int? { score.fullTime.home }

    /// Away team's current score.
    var awayScore: Int? { score.fullTime.away }

    // MARK: - Client-Side Status Inference

    /// The football-data.org free tier often returns stale `TIMED` status even
    /// when a match is live (lastUpdated can be days old). We infer the real
    /// status from the clock:
    /// - 0–135 min after kickoff → assume IN_PLAY (live match window)
    /// - >135 min after kickoff  → assume FINISHED (match ended)
    /// - Matches that already have FINISHED/IN_PLAY from the API are trusted.
    ///
    /// A full match lasts ~105 min (2 halves + halftime). With extra time and
    /// penalties, up to ~135 min. Beyond that, the match is done.
    var effectiveStatus: MatchStatus {
        // Trust explicit live/finished statuses from the API
        if status == .finished || status.isLive || status == .extraTime || status == .penaltyShootout {
            return status
        }

        // For TIMED/SCHEDULED, check the clock
        let now = Date()
        let elapsed = now.timeIntervalSince(utcDate)
        let matchWindow: TimeInterval = 135 * 60  // 135 minutes (2h15m)

        guard elapsed > 0 else {
            // Match hasn't started yet
            return status
        }

        if elapsed < matchWindow {
            // Within the live match window — the API just hasn't updated
            return .inPlay
        } else {
            // Past the match window — it must be finished
            return .finished
        }
    }

    /// Whether this match is currently live (uses effective status).
    var isLive: Bool { effectiveStatus.isLive }

    /// Whether this match has finished (uses effective status).
    var isFinished: Bool { effectiveStatus == .finished }

    /// The display string for the match time or score (uses effective status).
    var displayText: String {
        switch effectiveStatus {
        case .inPlay, .paused, .extraTime, .penaltyShootout, .finished:
            let h = homeScore ?? 0
            let a = awayScore ?? 0
            return "\(h) - \(a)"
        default:
            let formatter = DateFormatter()
            formatter.dateFormat = "h:mm a"
            formatter.timeZone = TimeZone.current
            return formatter.string(from: utcDate)
        }
    }

    /// Group display (e.g. "Group A" or "Round of 16").
    var groupDisplay: String? {
        if let group {
            return group.replacingOccurrences(of: "GROUP_", with: "Group ")
        }
        return stage?.replacingOccurrences(of: "_", with: " ").capitalized
    }
}

/// Score details for a match.
struct Score: Codable, Sendable {
    let winner: String?
    let duration: String?
    let fullTime: ScoreValues
    let halfTime: ScoreValues
}

/// Home/away score values.
struct ScoreValues: Codable, Sendable {
    let home: Int?
    let away: Int?
}
