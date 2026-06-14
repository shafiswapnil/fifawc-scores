import SwiftUI

/// Dynamic team-color theming based on the currently featured match.
/// Colors adapt to home/away teams for contextual visual identity.
enum TeamColors {

    /// Primary and secondary colors for a team TLA code.
    struct TeamColor {
        let primary: Color
        let secondary: Color
    }

    /// Hardcoded team color dictionary for FIFA World Cup 2026 participants.
    static let colors: [String: TeamColor] = [
        "ARG": TeamColor(primary: Color(red: 0.459, green: 0.667, blue: 0.859), secondary: .white),  // Light blue
        "BRA": TeamColor(primary: Color(red: 1.0, green: 0.875, blue: 0.0), secondary: Color(red: 0.0, green: 0.608, blue: 0.235)),  // Yellow/Green
        "FRA": TeamColor(primary: Color(red: 0.0, green: 0.137, blue: 0.584), secondary: Color(red: 0.929, green: 0.208, blue: 0.247)),  // Blue/Red
        "GER": TeamColor(primary: .black, secondary: Color(red: 0.859, green: 0.0, blue: 0.0)),  // Black/Red
        "ESP": TeamColor(primary: Color(red: 0.667, green: 0.082, blue: 0.106), secondary: Color(red: 0.945, green: 0.753, blue: 0.0)),  // Red/Yellow
        "ENG": TeamColor(primary: .white, secondary: Color(red: 0.812, green: 0.055, blue: 0.122)),  // White/Red
        "POR": TeamColor(primary: Color(red: 0.0, green: 0.4, blue: 0.0), secondary: Color(red: 1.0, green: 0.0, blue: 0.0)),  // Green/Red
        "NED": TeamColor(primary: Color(red: 1.0, green: 0.4, blue: 0.0), secondary: Color(red: 0.129, green: 0.275, blue: 0.545)),  // Orange/Blue
        "BEL": TeamColor(primary: .black, secondary: Color(red: 0.992, green: 0.831, blue: 0.141)),  // Black/Yellow
        "ITA": TeamColor(primary: Color(red: 0.0, green: 0.545, blue: 0.271), secondary: Color(red: 0.804, green: 0.067, blue: 0.165)),  // Green/Red
        "URU": TeamColor(primary: Color(red: 0.345, green: 0.835, blue: 0.937), secondary: Color(red: 0.992, green: 0.769, blue: 0.0)),  // Sky blue/Yellow
        "COL": TeamColor(primary: Color(red: 0.945, green: 0.816, blue: 0.086), secondary: Color(red: 0.0, green: 0.220, blue: 0.576)),  // Yellow/Blue
        "MEX": TeamColor(primary: Color(red: 0.0, green: 0.408, blue: 0.278), secondary: Color(red: 0.808, green: 0.067, blue: 0.149)),  // Green/Red
        "JPN": TeamColor(primary: Color(red: 0.737, green: 0.0, blue: 0.176), secondary: .white),  // Red/White
        "KOR": TeamColor(primary: Color(red: 0.0, green: 0.204, blue: 0.471), secondary: Color(red: 0.792, green: 0.063, blue: 0.188)),  // Blue/Red
        "AUS": TeamColor(primary: Color(red: 0.0, green: 0.518, blue: 0.239), secondary: Color(red: 0.0, green: 0.0, blue: 0.545)),  // Green/Navy
        "MAR": TeamColor(primary: Color(red: 0.757, green: 0.067, blue: 0.173), secondary: Color(red: 0.0, green: 0.384, blue: 0.2)),  // Red/Green
        "SEN": TeamColor(primary: Color(red: 0.0, green: 0.522, blue: 0.247), secondary: Color(red: 0.937, green: 0.200, blue: 0.251)),  // Green/Red
        "CMR": TeamColor(primary: Color(red: 0.0, green: 0.482, blue: 0.369), secondary: Color(red: 0.808, green: 0.067, blue: 0.149)),  // Green/Red
        "GHA": TeamColor(primary: Color(red: 0.0, green: 0.420, blue: 0.247), secondary: Color(red: 0.992, green: 0.831, blue: 0.0)),  // Green/Yellow
        "NGA": TeamColor(primary: Color(red: 0.0, green: 0.533, blue: 0.318), secondary: .white),  // Green/White
        "POL": TeamColor(primary: .white, secondary: Color(red: 0.863, green: 0.078, blue: 0.235)),  // White/Red
        "SUI": TeamColor(primary: Color(red: 1.0, green: 0.0, blue: 0.0), secondary: .white),  // Red/White
        "CRO": TeamColor(primary: Color(red: 0.0, green: 0.247, blue: 0.545), secondary: Color(red: 1.0, green: 0.0, blue: 0.0)),  // Blue/Red
        "DEN": TeamColor(primary: Color(red: 0.784, green: 0.063, blue: 0.180), secondary: .white),  // Red/White
        "SWE": TeamColor(primary: Color(red: 0.0, green: 0.416, blue: 0.655), secondary: Color(red: 0.996, green: 0.808, blue: 0.012)),  // Blue/Yellow
        "SRB": TeamColor(primary: Color(red: 0.863, green: 0.078, blue: 0.235), secondary: Color(red: 0.0, green: 0.247, blue: 0.545)),  // Red/Blue
        "UKR": TeamColor(primary: Color(red: 0.0, green: 0.502, blue: 0.835), secondary: Color(red: 1.0, green: 0.882, blue: 0.0)),  // Blue/Yellow
        "TUR": TeamColor(primary: Color(red: 0.863, green: 0.078, blue: 0.235), secondary: .white),  // Red/White
        "SCO": TeamColor(primary: Color(red: 0.0, green: 0.247, blue: 0.545), secondary: .white),  // Blue/White
        "CZE": TeamColor(primary: Color(red: 0.863, green: 0.078, blue: 0.235), secondary: Color(red: 0.0, green: 0.247, blue: 0.545)),  // Red/Blue
        "AUT": TeamColor(primary: Color(red: 0.863, green: 0.078, blue: 0.235), secondary: .white),  // Red/White
        "SRB": TeamColor(primary: Color(red: 0.863, green: 0.078, blue: 0.235), secondary: Color(red: 0.0, green: 0.247, blue: 0.545)),  // Red/Blue
        "ROU": TeamColor(primary: Color(red: 0.0, green: 0.224, blue: 0.663), secondary: Color(red: 1.0, green: 0.808, blue: 0.0)),  // Blue/Yellow
        "HUN": TeamColor(primary: Color(red: 0.804, green: 0.067, blue: 0.165), secondary: Color(red: 0.0, green: 0.533, blue: 0.267)),  // Red/Green
        "GRE": TeamColor(primary: Color(red: 0.0, green: 0.314, blue: 0.686), secondary: .white),  // Blue/White
        "NZL": TeamColor(primary: .black, secondary: .white),  // Black/White
        "CAN": TeamColor(primary: Color(red: 0.863, green: 0.078, blue: 0.235), secondary: .white),  // Red/White
        "USA": TeamColor(primary: Color(red: 0.235, green: 0.231, blue: 0.431), secondary: Color(red: 0.741, green: 0.133, blue: 0.208)),  // Navy/Red
    ]

    /// Get team colors for a TLA. Returns a default if not found.
    static func forTeam(_ tla: String) -> TeamColor {
        colors[tla] ?? TeamColor(primary: Color.accentColor, secondary: .white)
    }

    /// Blended accent color from a home/away match pair.
    static func matchAccent(homeTla: String, awayTla: String) -> Color {
        let home = forTeam(homeTla).primary
        return home
    }
}
