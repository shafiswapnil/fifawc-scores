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

    /// Whether this match is currently live.
    var isLive: Bool { status.isLive }

    /// Whether this match has finished.
    var isFinished: Bool { status == .finished }

    /// The display string for the match time or score.
    var displayText: String {
        switch status {
        case .inPlay, .paused:
            let h = homeScore ?? 0
            let a = awayScore ?? 0
            return "\(h) - \(a)"
        case .finished:
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
