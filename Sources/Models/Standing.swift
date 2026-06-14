import Foundation

/// A single team's standing entry within a group table.
/// Maps to football-data.org's `table` array items.
struct StandingEntry: Codable, Sendable, Identifiable {
    var id: String { team.tla }

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
    let form: String?

    /// Whether this team qualifies (top 2 in group).
    var isQualified: Bool { position <= 2 }

    /// Short form of goal difference (e.g. "+5", "-2", "0").
    var goalDifferenceText: String {
        if goalDifference > 0 { return "+\(goalDifference)" }
        return "\(goalDifference)"
    }
}

/// A complete group table — maps to football-data.org's standings array item.
/// Each item has a `group` and a `table` array of team entries.
struct GroupStanding: Codable, Sendable, Identifiable {
    var id: String { group }

    let stage: String?
    let type: String?
    let group: String
    let table: [StandingEntry]

    /// Display name (e.g. "Group A").
    var displayName: String {
        group.replacingOccurrences(of: "GROUP_", with: "Group ")
    }
}
