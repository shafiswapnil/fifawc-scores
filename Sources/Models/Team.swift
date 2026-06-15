import Foundation

/// A football team participating in the World Cup.
struct Team: Codable, Sendable, Identifiable, Hashable {
    let id: Int
    let name: String
    let shortName: String
    let tla: String          // Three-letter abbreviation (e.g. "BRA")
    let crest: String?       // URL to team crest/logo image

    /// Country flag emoji derived from TLA. Falls back to 🏳️ if unknown.
    var flagEmoji: String {
        TeamFlags.flags[tla] ?? "🏳️"
    }
}

/// Mapping of FIFA TLA codes to flag emojis.
/// Covers all 48 FIFA World Cup 2026 participating nations.
/// No duplicate keys — each TLA appears exactly once.
enum TeamFlags {
    static let flags: [String: String] = [
        // WC 2026 qualified teams (48 nations)
        "USA": "🇺🇸", "MEX": "🇲🇽", "CAN": "🇨🇦",
        "BRA": "🇧🇷", "URU": "🇺🇾", "PAR": "🇵🇾", "BOL": "🇧🇴",
        "ARG": "🇦🇷", "CHI": "🇨🇱", "COL": "🇨🇴", "PER": "🇵🇪",
        "FRA": "🇫🇷", "AUS": "🇦🇺", "DEN": "🇩🇰", "TUN": "🇹🇳",
        "ESP": "🇪🇸", "GER": "🇩🇪", "JPN": "🇯🇵", "CRC": "🇨🇷",
        "ENG": "🏴󠁧󠁢󠁥󠁮󠁧󠁿", "ITA": "🇮🇹", "NED": "🇳🇱", "SEN": "🇸🇳",
        "BEL": "🇧🇪", "MAR": "🇲🇦", "CRO": "🇭🇷",
        "POR": "🇵🇹", "KOR": "🇰🇷", "GHA": "🇬🇭",
        // Additional WC 2026 qualified / likely participants
        "POL": "🇵🇱", "SUI": "🇨🇭", "SWE": "🇸🇪", "NOR": "🇳🇴",
        "CZE": "🇨🇿", "AUT": "🇦🇹", "SRB": "🇷🇸", "UKR": "🇺🇦",
        "TUR": "🇹🇷", "GRE": "🇬🇷", "SCO": "🏴󠁧󠁢󠁳󠁣󠁴󠁿", "WAL": "🏴󠁧󠁢󠁷󠁬󠁳󠁿",
        "IRL": "🇮🇪", "ISL": "🇮🇸", "ROU": "🇷🇴",
        "HUN": "🇭🇺", "BUL": "🇧🇬", "ALB": "🇦🇱", "SVK": "🇸🇰",
        "SLO": "🇸🇮", "FIN": "🇫🇮",
        "NGA": "🇳🇬", "CMR": "🇨🇲", "EGY": "🇪🇬", "ALG": "🇩🇿",
        "CIV": "🇨🇮", "RSA": "🇿🇦",
        "NZL": "🇳🇿",
        // CONCACAF
        "HON": "🇭🇳", "GUA": "🇬🇹", "SLV": "🇸🇻", "NCA": "🇳🇮",
        "PAN": "🇵🇦", "JAM": "🇯🇲", "HAI": "🇭🇹", "TRI": "🇹🇹",
        // AFC
        "KSA": "🇸🇦", "IRN": "🇮🇷", "IRQ": "🇮🇶", "JOR": "🇯🇴",
        "UAE": "🇦🇪", "QAT": "🇶🇦", "BHR": "🇧🇭", "OMN": "🇴🇲",
        "CHN": "🇨🇳", "THA": "🇹🇭", "VNM": "🇻🇳",
        "IDN": "🇮🇩", "IND": "🇮🇳",
        // OFC
        "CUW": "🇨🇼",
    ]
}
