import SwiftUI

/// The compact menu bar label. Shows the match status in the menu bar area.
///
/// Three states:
/// - **Idle**: `⚽ FWC` (no match today or no data yet)
/// - **Upcoming**: `⚽ BRA vs ARG · 3:00 PM`
/// - **Live**: `⚽ BRA 2 - 1 ARG · 67'`
struct MenuBarLabel: View {
    @Environment(MatchStore.self) private var store

    var body: some View {
        HStack(spacing: 4) {
            // Goal animation overlay
            ZStack(alignment: .leading) {
                Text("⚽")
                    .font(.system(size: 13))
                if store.goalScored {
                    GoalAnimationView()
                        .allowsHitTesting(false)
                }
            }

            Text(labelText)
                .font(.system(size: 13))
                .monospacedDigit()
                .foregroundStyle(labelColor)
        }
        .contentTransition(.numericText())
        .animation(.default, value: labelText)
    }

    // MARK: - Label Text

    private var labelText: String {
        guard let match = store.featuredMatch else {
            return "FWC"
        }

        switch match.status {
        case .inPlay, .paused:
            // Live: "BRA 2 - 1 ARG · 67'"
            let h = match.homeScore ?? 0
            let a = match.awayScore ?? 0
            let minute = elapsedMinute(match)
            return "\(match.homeTeam.tla) \(h) - \(a) \(match.awayTeam.tla) · \(minute)'"

        case .finished:
            // Finished: "BRA 2 - 1 ARG · FT"
            let h = match.homeScore ?? 0
            let a = match.awayScore ?? 0
            return "\(match.homeTeam.tla) \(h) - \(a) \(match.awayTeam.tla) · FT"

        default:
            // Upcoming: "BRA vs ARG · 3:00 PM"
            let time = formattedTime(match.utcDate)
            return "\(match.homeTeam.tla) vs \(match.awayTeam.tla) · \(time)"
        }
    }

    // MARK: - Label Color

    private var labelColor: Color {
        guard let match = store.featuredMatch else {
            return .primary
        }

        if match.isLive {
            return TeamColors.forTeam(match.homeTeam.tla).primary
        }

        return .primary
    }

    // MARK: - Helpers

    /// Format kickoff time in user's local timezone.
    private func formattedTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        formatter.timeZone = TimeZone.current
        return formatter.string(from: date)
    }

    /// Calculate elapsed minute for a live match (approximate, based on UTC times).
    private func elapsedMinute(_ match: Match) -> Int {
        let elapsed = Date().timeIntervalSince(match.utcDate)
        let minutes = Int(elapsed / 60)
        return max(1, min(minutes, 120)) // Clamp 1–120 (extra time)
    }
}

// MARK: - Goal Animation

/// Tiny football emoji that slides left-to-right across the menu bar text.
/// Appears when a goal is detected and auto-removes after 1.5s.
struct GoalAnimationView: View {
    @State private var offset: CGFloat = -20
    @State private var opacity: Double = 0

    var body: some View {
        Text("⚽")
            .font(.system(size: 11))
            .offset(x: offset)
            .opacity(opacity)
            .onAppear {
                withAnimation(.easeInOut(duration: 1.5)) {
                    offset = 200
                    opacity = 1
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    withAnimation { opacity = 0 }
                }
            }
    }
}

// MARK: - Preview

#Preview {
    MenuBarLabel()
        .environment(MatchStore())
}
