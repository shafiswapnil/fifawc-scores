import Foundation

/// A group standing entry in the tournament table.
struct Standing: Codable, Sendable, Identifiable {
    var id: String { "\(group)-\(team.tla)" }

    let position: Int
    let team: Team
    let playedGames: Int
    let won: Int
    let draw: Int
    let lost: Int
    let points: Int
    let goalsFor: Int
    let goalsAgainst: Int
    let goalDifference: Int

    var form: String? { nil }  // Future: "W,W,D,L,W"

    /// Whether this team qualifies (top 2 in group).
    var isQualified: Bool { position <= 2 }

    /// Short form of goal difference (e.g. "+5", "-2", "0").
    var goalDifferenceText: String {
        if goalDifference > 0 { return "+\(goalDifference)" }
        return "\(goalDifference)"
    }
}

/// A complete group table with all team standings.
struct GroupStanding: Codable, Sendable, Identifiable {
    var id: String { group }

    let group: String
    let standings: [Standing]

    /// Display name (e.g. "Group A").
    var displayName: String {
        group.replacingOccurrences(of: "GROUP_", with: "Group ")
    }
}
