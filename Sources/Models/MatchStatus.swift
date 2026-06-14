import Foundation

/// The possible states of a football match, mirroring football-data.org's status values.
enum MatchStatus: String, Codable, Sendable {
    case scheduled = "SCHEDULED"
    case timed = "TIMED"
    case inPlay = "IN_PLAY"
    case paused = "PAUSED"
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
        case .finished: "FT"
        case .postponed: "Postponed"
        case .suspended: "Suspended"
        case .cancelled: "Cancelled"
        case .awarded: "Awarded"
        }
    }

    var isLive: Bool { self == .inPlay || self == .paused }
    var hasStarted: Bool { self == .inPlay || self == .paused || self == .finished }
}
