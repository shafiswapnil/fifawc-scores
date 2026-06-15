import SwiftUI

/// The compact menu bar label. Always visible in the menu bar — no click needed.
///
/// **States (priority order):**
/// - **Live**:     `⚽ BRA 2 - 1 ARG · 67'`
/// - **HT**:       `⚽ BRA 0 - 0 ARG · HT`
/// - **Finished**: `⚽ BRA 2 - 1 ARG · FT`
/// - **Upcoming**: `⚽ BRA vs ARG · 3:00 PM`
/// - **Idle**:     `⚽ FWC`
///
/// Real-time minute ticking comes from `store.minuteTick` — an `@Observable`
/// Date property on MatchStore updated every 60 s by a Task loop.
/// This avoids `TimelineView`, which hangs inside MenuBarExtra labels on macOS.
struct MenuBarLabel: View {
    @Environment(MatchStore.self) private var store

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "soccerball")
                .font(.system(size: 13))

            Text(store.goalScored ? "GOAL!" : labelText(at: store.minuteTick))
                .font(.system(size: 13))
                .monospacedDigit()
        }
    }

    // MARK: - Label Text

    private func labelText(at date: Date) -> String {
        guard let match = store.featuredMatch else {
            return "FWC"
        }

        switch match.effectiveStatus {
        case .paused:
            let h = match.homeScore ?? 0
            let a = match.awayScore ?? 0
            return "\(match.homeTeam.tla) \(h) - \(a) \(match.awayTeam.tla) · HT"

        case .inPlay, .extraTime, .penaltyShootout:
            let h = match.homeScore ?? 0
            let a = match.awayScore ?? 0
            let minute = elapsedMinute(match, at: date)
            return "\(match.homeTeam.tla) \(h) - \(a) \(match.awayTeam.tla) · \(minute)'"

        case .finished:
            let h = match.homeScore ?? 0
            let a = match.awayScore ?? 0
            return "\(match.homeTeam.tla) \(h) - \(a) \(match.awayTeam.tla) · FT"

        default:
            return "\(match.homeTeam.tla) vs \(match.awayTeam.tla) · \(formattedTime(match.utcDate))"
        }
    }

    // MARK: - Helpers

    private func formattedTime(_ date: Date) -> String {
        let fmt = DateFormatter()
        fmt.dateFormat = "h:mm a"
        fmt.timeZone = TimeZone.current
        return fmt.string(from: date)
    }

    private func elapsedMinute(_ match: Match, at date: Date) -> Int {
        let elapsed = date.timeIntervalSince(match.utcDate)
        return max(1, min(Int(elapsed / 60), 120))
    }
}

// MARK: - Preview

#Preview {
    MenuBarLabel()
        .environment(MatchStore())
}
