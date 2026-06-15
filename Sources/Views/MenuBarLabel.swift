import SwiftUI

/// The compact menu bar label. Shows the match status in the menu bar area.
///
/// Three states:
/// - **Idle**: `⚽ FWC` (no match today or no data yet)
/// - **Upcoming**: `⚽ BRA vs ARG · 3:00 PM`
/// - **Live**: `⚽ BRA 2 - 1 ARG · 67'`
///
/// **Design rule**: The menu bar label is MINIMAL. No color changes, no
/// animations, no dynamic layout. Just ⚽ + static text. All visual
/// richness lives in the panel (MatchCard, pulsing dot, team colors).
/// The label re-renders only when `matchesByDate` or `goalScored` change
/// (i.e., on data fetch), NOT every second. This prevents the menu bar
/// wobble that caused by the 1s @Observable clock tick.
struct MenuBarLabel: View {
    @Environment(MatchStore.self) private var store

    var body: some View {
        HStack(spacing: 4) {
            Text("⚽")
                .font(.system(size: 13))

            Text(labelText)
                .font(.system(size: 13))
                .monospacedDigit()
        }
    }

    // MARK: - Label Text

    private var labelText: String {
        guard let match = store.featuredMatch else {
            return "FWC"
        }

        switch match.effectiveStatus {
        case .inPlay, .paused, .extraTime, .penaltyShootout:
            // Live: "CIV 0 - 0 ECU · 30'"
            let h = match.homeScore ?? 0
            let a = match.awayScore ?? 0
            let minute = elapsedMinute(match)
            return "\(match.homeTeam.tla) \(h) - \(a) \(match.awayTeam.tla) · \(minute)'"

        case .finished:
            // Finished: "CIV 0 - 0 ECU · FT"
            let h = match.homeScore ?? 0
            let a = match.awayScore ?? 0
            return "\(match.homeTeam.tla) \(h) - \(a) \(match.awayTeam.tla) · FT"

        default:
            // Upcoming: "BRA vs ARG · 3:00 PM"
            let time = formattedTime(match.utcDate)
            return "\(match.homeTeam.tla) vs \(match.awayTeam.tla) · \(time)"
        }
    }

    // MARK: - Helpers

    /// Format kickoff time in user's local timezone.
    private func formattedTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        formatter.timeZone = TimeZone.current
        return formatter.string(from: date)
    }

    /// Elapsed minute for a live match.
    /// Uses Date() directly — NOT store.now — to avoid triggering
    /// @Observable re-renders every second. The minute is computed fresh
    /// each time body IS re-evaluated (on data fetch), which is accurate
    /// enough for a menu bar indicator. This prevents the wobble.
    private func elapsedMinute(_ match: Match) -> Int {
        let elapsed = Date().timeIntervalSince(match.utcDate)
        let minutes = Int(elapsed / 60)
        return max(1, min(minutes, 120)) // Clamp 1–120 (extra time)
    }
}

// MARK: - Preview

#Preview {
    MenuBarLabel()
        .environment(MatchStore())
}
