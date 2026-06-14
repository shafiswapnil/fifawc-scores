import Foundation

/// The possible states of a football match, mirroring football-data.org's status values.
/// See https://docs.football-data.org/general/v4/lookup_tables.html
enum MatchStatus: String, Codable, Sendable {
    case scheduled = "SCHEDULED"
    case timed = "TIMED"
    case inPlay = "IN_PLAY"
    case paused = "PAUSED"
    case extraTime = "EXTRA_TIME"
    case penaltyShootout = "PENALTY_SHOOTOUT"
    case finished = "FINISHED"
    case postponed = "POSTPONED"
    case suspended = "SUSPENDED"
    case cancelled = "CANCELLED"
    case awarded = "AWARDED"

    var displayName: String {
        switch self {
        case .scheduled: "Scheduled"
        case .timed: "Timed"
        case .inPlay: "Live"
        case .paused: "Half Time"
        case .extraTime: "Extra Time"
        case .penaltyShootout: "Penalties"
        case .finished: "FT"
        case .postponed: "Postponed"
        case .suspended: "Suspended"
        case .cancelled: "Cancelled"
        case .awarded: "Awarded"
        }
    }

    /// Whether the match is actively in progress (any non-paused live state).
    var isLive: Bool {
        self == .inPlay || self == .paused || self == .extraTime || self == .penaltyShootout
    }

    /// Whether the match has kicked off (started playing).
    var hasStarted: Bool {
        self == .inPlay || self == .paused || self == .extraTime || self == .penaltyShootout || self == .finished
    }
}
