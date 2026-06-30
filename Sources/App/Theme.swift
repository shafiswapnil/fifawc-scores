import SwiftUI

/// TRIONDA — the app's color system, pulled from the 3D icon gradient.
/// Single source of truth for all UI colors across the app.
enum Theme {

    // MARK: - Brand Colors

    /// Vibrant Orange — primary accent for active states, live indicators, toggles.
    static let orange = Color(hex: "F26622")

    /// Deep Violet — secondary accent for selected items, subtle background tints.
    static let violet = Color(hex: "5B0A82")

    /// Warm Magenta — mid-tone bridge for gradients, alerts, less critical accents.
    static let magenta = Color(hex: "C32B5A")

    // MARK: - Text Colors

    /// Pure White — primary text (scores, team names, active labels).
    static let textPrimary = Color.white

    /// Muted Silver — secondary text (times, groups, metadata, links).
    static let textSecondary = Color(hex: "9CA3AF")

    /// Light Gray — completed/dimmed scores.
    static let textDimmed = Color(hex: "D1D5DB")

    // MARK: - Surface Colors

    /// Panel background — solid dark fill that works in both Debug and Release.
    /// This is the foundation of production-safe dark mode: we control the bg
    /// instead of relying on system appearance hacks.
    static let panelBackground = Color(white: 0.11)

    /// Dark charcoal — card background fill.
    static let cardBackground = Color(hex: "242429")

    /// Subtle dark — grid item background, search field background.
    static let surfaceSubtle = Color(hex: "1E1E1E")

    /// 1px glass stroke — card borders, grid item borders.
    static let glassStroke = Color.white.opacity(0.08)

    /// Tab active background — translucent dark pill.
    static let tabActiveBackground = Color.white.opacity(0.1)

    /// Tab inactive background — very subtle fill.
    static let tabInactiveBackground = Color.primary.opacity(0.06)

    // MARK: - Status Colors

    /// Live indicator dot and text — Vibrant Orange (replaces red).
    static let live = Color(hex: "F26622")

    /// Finished score — dimmed white.
    static let finished = Color(hex: "D1D5DB")

    /// Qualified row tint — subtle orange glow.
    static let qualifiedTint = Color(hex: "F26622").opacity(0.06)

    // MARK: - Favorite Team

    /// Favorite team highlight — subtle orange card glow.
    static let favHighlight = Color(hex: "F26622").opacity(0.06)

    /// Favorite team border — visible orange stroke.
    static let favBorder = Color(hex: "F26622").opacity(0.35)
}

// MARK: - Hex Init

extension Color {
    /// Initialize a Color from a hex string (e.g. "F26622").
    init(hex: String) {
        let scanner = Scanner(string: hex)
        var rgbValue: UInt64 = 0
        scanner.scanHexInt64(&rgbValue)
        let r = Double((rgbValue & 0xFF0000) >> 16) / 255.0
        let g = Double((rgbValue & 0x00FF00) >> 8) / 255.0
        let b = Double(rgbValue & 0x0000FF) / 255.0
        self.init(red: r, green: g, blue: b)
    }
}
