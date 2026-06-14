import SwiftUI

/// The `.window`-style panel shown when the menu bar item is clicked.
/// Contains tabbed navigation for Today, Yesterday, Tomorrow, Full Schedule, Standings.
struct MenuBarPanel: View {
    @Environment(MatchStore.self) private var store

    let checkForUpdates: () -> Void

    @State private var selectedTab: PanelTab = .today
    @State private var fullScheduleStartDate: Date = Calendar.current.date(from: Calendar.current.dateComponents([.year, .month, .day], from: Date()))!

    enum PanelTab: String, CaseIterable {
        case today = "Today"
        case yesterday = "Yesterday"
        case tomorrow = "Tomorrow"
        case fullSchedule = "Schedule"
        case standings = "Standings"
        case settings = "⚙️"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            Divider().opacity(0.5)
            tabRow
            Divider().opacity(0.3)
            content
            Divider().opacity(0.5)
            footer
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 12)
        .frame(width: 340)
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("FIFA WORLD CUP 2026")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .tracking(0.5)

                if store.isFetching {
                    Text("Syncing…")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                } else if let error = store.errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                        .lineLimit(1)
                } else if let match = store.featuredMatch, match.isLive {
                    Text("🔴 LIVE")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(.red)
                } else {
                    Text("⚽ Match Hub")
                        .font(.title3.weight(.semibold))
                }
            }
            Spacer()
        }
        .padding(.horizontal, 8)
        .padding(.bottom, 8)
    }

    // MARK: - Tab Row

    private var tabRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(PanelTab.allCases, id: \.self) { tab in
                    Button {
                        withAnimation(.easeInOut(duration: 0.15)) {
                            selectedTab = tab
                        }
                    } label: {
                        Text(tab.rawValue)
                            .font(.caption.weight(.medium))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(
                                Capsule()
                                    .fill(selectedTab == tab
                                          ? Color.accentColor
                                          : Color.clear)
                            )
                            .foregroundStyle(selectedTab == tab ? .white : .secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
        }
    }

    // MARK: - Content

    @ViewBuilder
    private var content: some View {
        switch selectedTab {
        case .today:
            matchList(store.todayMatches, emptyText: "No matches today")
        case .yesterday:
            matchList(store.yesterdayMatches, emptyText: "No matches yesterday")
        case .tomorrow:
            matchList(store.tomorrowMatches, emptyText: "No matches tomorrow")
        case .fullSchedule:
            fullScheduleView
        case .standings:
            standingsList
        case .settings:
            settingsView
        }
    }

    // MARK: - Match List

    private func matchList(_ matches: [Match], emptyText: String) -> some View {
        Group {
            if matches.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "calendar")
                        .font(.title2)
                        .foregroundStyle(.tertiary)
                    Text(emptyText)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, minHeight: 120)
            } else {
                ScrollView {
                    LazyVStack(spacing: 6) {
                        // Live matches first
                        let live = matches.filter { $0.isLive }
                        if !live.isEmpty {
                            ForEach(live) { match in
                                MatchCard(match: match, isLiveHighlight: true)
                            }
                            Divider().opacity(0.3)
                        }

                        // Upcoming matches (sorted by time)
                        let upcoming = matches
                            .filter { !$0.status.hasStarted }
                            .sorted { $0.utcDate < $1.utcDate }
                        if !upcoming.isEmpty {
                            ForEach(upcoming) { match in
                                MatchCard(match: match, isLiveHighlight: false)
                            }
                        }

                        // Finished matches (most recent first)
                        let finished = matches
                            .filter { $0.isFinished }
                            .sorted { $0.utcDate > $1.utcDate }
                        if !finished.isEmpty {
                            if !upcoming.isEmpty || !live.isEmpty {
                                Divider().opacity(0.3)
                            }
                            ForEach(finished) { match in
                                MatchCard(match: match, isLiveHighlight: false)
                            }
                        }
                    }
                    .padding(.vertical, 6)
                }
                .frame(maxHeight: 300)
            }
        }
        .padding(.horizontal, 8)
    }

    // MARK: - Standings

    private var standingsList: some View {
        Group {
            if store.standings.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "list.number")
                        .font(.title2)
                        .foregroundStyle(.tertiary)
                    Text("No standings available")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, minHeight: 120)
            } else {
                ScrollView {
                    LazyVStack(spacing: 10) {
                        ForEach(store.standings) { group in
                            GroupStandingCard(group: group)
                        }
                    }
                    .padding(.vertical, 6)
                }
                .frame(maxHeight: 300)
            }
        }
        .padding(.horizontal, 8)
    }

    // MARK: - Settings

    private var settingsView: some View {
        VStack(alignment: .leading, spacing: 12) {
            // API Key
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("API Key")
                        .font(.caption.weight(.medium))
                    if store.hasApiKey {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                            .font(.caption2)
                    } else {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.orange)
                            .font(.caption2)
                    }
                }
                TextField("Paste your API key here", text: Binding(
                    get: { store.apiKey },
                    set: { store.apiKey = $0 }
                ))
                .textFieldStyle(.roundedBorder)
                .font(.caption)
                HStack(spacing: 4) {
                    Text("Free at")
                    Link("football-data.org", destination: URL(string: "https://www.football-data.org/client/register")!)
                        .font(.caption2)
                }
                .foregroundStyle(.tertiary)
            }

            Divider().opacity(0.3)

            // Poll interval
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Live Poll Interval")
                        .font(.caption.weight(.medium))
                    Spacer()
                    Text("\(Int(store.pollInterval))s")
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
                Slider(
                    value: Binding(
                        get: { store.pollInterval },
                        set: { store.pollInterval = $0 }
                    ),
                    in: 60...300,
                    step: 30
                )
                Text("Min 60s · Higher = less API usage")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }

            Divider().opacity(0.3)

            // Favorite team
            VStack(alignment: .leading, spacing: 4) {
                Text("Favorite Team")
                    .font(.caption.weight(.medium))

                Text("Prioritized in menu bar when upcoming")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)

                HStack(spacing: 6) {
                    Button {
                        store.favoriteTeam = nil
                    } label: {
                        Text("None")
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                Capsule()
                                    .fill(store.favoriteTeam == nil
                                          ? Color.accentColor
                                          : Color.primary.opacity(0.08))
                            )
                            .foregroundStyle(store.favoriteTeam == nil ? .white : .secondary)
                    }
                    .buttonStyle(.plain)

                    // Common favorites
                    ForEach(["BRA", "ARG", "FRA", "GER", "ESP", "ENG"], id: \.self) { tla in
                        Button {
                            store.favoriteTeam = tla
                        } label: {
                            Text("\(TeamFlags.flags[tla] ?? "⚽") \(tla)")
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(
                                    Capsule()
                                        .fill(store.favoriteTeam == tla
                                              ? Color.accentColor
                                              : Color.primary.opacity(0.08))
                                )
                                .foregroundStyle(store.favoriteTeam == tla ? .white : .secondary)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            Divider().opacity(0.3)

            // Check for Updates
            Button {
                checkForUpdates()
            } label: {
                HStack {
                    Image(systemName: "arrow.down.circle")
                    Text("Check for Updates…")
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 5)
                .padding(.horizontal, 8)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .menuRowHighlight()

            Divider().opacity(0.3)

            // App info
            HStack {
                Text("FIFAWC Scores v1.0")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                Spacer()
                if let lastFetch = store.lastFetchTime {
                    Text("Updated \(lastFetch, style: .relative) ago")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
    }

    // MARK: - Full Schedule

    private var fullScheduleView: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Date picker
            HStack {
                DatePicker(
                    "From",
                    selection: $fullScheduleStartDate,
                    displayedComponents: .date
                )
                .datePickerStyle(.compact)
                .labelsHidden()
                .font(.caption)
            }
            .padding(.horizontal, 8)
            .padding(.top, 6)

            // Matches from start date onward
            let filteredMatches = store.allMatches
                .filter { $0.utcDate >= fullScheduleStartDate }
                .sorted { $0.utcDate < $1.utcDate }

            if filteredMatches.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "calendar.badge.exclamationmark")
                        .font(.title2)
                        .foregroundStyle(.tertiary)
                    Text("No scheduled matches from this date")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, minHeight: 120)
            } else {
                ScrollView {
                    LazyVStack(spacing: 2) {
                        // Group by date
                        let grouped = Dictionary(grouping: filteredMatches) { match in
                            dateStringForSchedule(match.utcDate)
                        }
                        let sortedKeys = grouped.keys.sorted()

                        ForEach(sortedKeys, id: \.self) { dateKey in
                            if let dayMatches = grouped[dateKey] {
                                // Date header
                                Text(headerForDate(dateKey))
                                    .font(.caption2.weight(.semibold))
                                    .foregroundStyle(.secondary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.horizontal, 8)
                                    .padding(.top, 8)
                                    .padding(.bottom, 2)

                                ForEach(dayMatches) { match in
                                    MatchCard(match: match, isLiveHighlight: match.isLive)
                                }
                            }
                        }
                    }
                    .padding(.vertical, 6)
                }
                .frame(maxHeight: 300)
            }
        }
        .padding(.horizontal, 8)
    }

    // MARK: - Full Schedule Helpers

    private func dateStringForSchedule(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        return formatter.string(from: date)
    }

    private func headerForDate(_ key: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        guard let date = formatter.date(from: key) else { return key }
        formatter.dateFormat = "EEE, MMM d"
        formatter.timeZone = .current
        return formatter.string(from: date)
    }

    // MARK: - Footer

    private var footer: some View {
        VStack(spacing: 1) {
            Button {
                Task { await store.sync() }
            } label: {
                HStack {
                    if store.isFetching {
                        ProgressView()
                            .controlSize(.mini)
                    } else {
                        Image(systemName: "arrow.triangle.2.circlepath")
                    }
                    Text("Sync")
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 5)
                .padding(.horizontal, 8)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .menuRowHighlight()
            .disabled(store.isFetching)

            Button { NSApplication.shared.terminate(nil) } label: {
                Label("Quit", systemImage: "power")
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 5)
                    .padding(.horizontal, 8)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .menuRowHighlight()
        }
        .font(.callout)
        .padding(.top, 4)
    }
}

// MARK: - Match Card

/// A compact card showing one match with flags, scores, status, and group.
struct MatchCard: View {
    let match: Match
    let isLiveHighlight: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            // Main row: flags + teams + score/time
            HStack(spacing: 0) {
                // Home team
                Text(match.homeTeam.flagEmoji)
                    .font(.system(size: 14))
                Text("  ")
                Text(match.homeTeam.tla)
                    .font(.caption.weight(.semibold))
                    .frame(width: 32, alignment: .leading)

                Spacer()

                // Score or time
                Text(match.displayText)
                    .font(.system(.caption, design: .monospaced).weight(.bold))
                    .foregroundStyle(isLiveHighlight ? Color.red : .primary)

                Spacer()

                // Away team
                Text(match.awayTeam.tla)
                    .font(.caption.weight(.semibold))
                    .frame(width: 32, alignment: .trailing)
                Text("  ")
                Text(match.awayTeam.flagEmoji)
                    .font(.system(size: 14))
            }

            // Status row: minute/status + group + venue
            HStack {
                if match.isLive {
                    HStack(spacing: 3) {
                        Circle()
                            .fill(.red)
                            .frame(width: 5, height: 5)
                        Text(match.status.displayName)
                            .foregroundStyle(.red)
                    }
                    .font(.caption2.weight(.medium))
                } else if match.isFinished {
                    Text("FT")
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(.secondary)
                } else {
                    Image(systemName: "clock")
                        .font(.system(size: 8))
                    Text(match.status.displayName)
                }

                if let group = match.groupDisplay {
                    Text("·")
                    Text(group)
                }

                Spacer()

                if let venue = match.venue {
                    Text(venue)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                        .lineLimit(1)
                }
            }
            .font(.caption2)
            .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(isLiveHighlight
                      ? Color.red.opacity(0.06)
                      : Color.primary.opacity(0.03))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(isLiveHighlight ? Color.red.opacity(0.15) : Color.clear, lineWidth: 0.5)
        )
    }
}

// MARK: - Group Standing Card

/// A mini group table showing team positions, points, and goal difference.
struct GroupStandingCard: View {
    let group: GroupStanding

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            // Group header
            Text(group.displayName)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 4)

            // Table header
            HStack {
                Text("Team")
                    .frame(width: 80, alignment: .leading)
                Spacer()
                Text("P")
                    .frame(width: 20)
                Text("W")
                    .frame(width: 20)
                Text("D")
                    .frame(width: 20)
                Text("L")
                    .frame(width: 20)
                Text("GD")
                    .frame(width: 28)
                Text("Pts")
                    .frame(width: 28)
            }
            .font(.system(size: 9, weight: .medium, design: .monospaced))
            .foregroundStyle(.tertiary)
            .padding(.horizontal, 4)

            // Team rows
            ForEach(group.table) { entry in
                HStack(spacing: 0) {
                    Text("\(entry.position).")
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundStyle(.secondary)
                        .frame(width: 16, alignment: .trailing)

                    Text(entry.team.flagEmoji)
                        .font(.system(size: 11))

                    Text(entry.team.tla)
                        .font(.system(size: 10, weight: .semibold))
                        .frame(width: 36, alignment: .leading)

                    Spacer()

                    Text("\(entry.playedGames)")
                        .frame(width: 20)
                    Text("\(entry.won)")
                        .frame(width: 20)
                    Text("\(entry.draw)")
                        .frame(width: 20)
                    Text("\(entry.lost)")
                        .frame(width: 20)
                    Text(entry.goalDifferenceText)
                        .frame(width: 28)
                        .foregroundStyle(entry.goalDifference > 0 ? .green
                                         : entry.goalDifference < 0 ? .red : .secondary)
                    Text("\(entry.points)")
                        .frame(width: 28)
                        .fontWeight(.bold)
                }
                .font(.system(size: 10, design: .monospaced))
                .padding(.horizontal, 4)
                .padding(.vertical, 2)
                .background(entry.isQualified
                            ? Color.accentColor.opacity(0.06)
                            : Color.clear)
            }
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.primary.opacity(0.03))
        )
    }
}

// MARK: - Menu Row Highlight

private struct MenuRowHighlight: ViewModifier {
    @State private var hovering = false

    func body(content: Content) -> some View {
        content
            .background(hovering ? Color.primary.opacity(0.08) : Color.clear)
            .onHover { hovering = $0 }
    }
}

extension View {
    func menuRowHighlight() -> some View {
        modifier(MenuRowHighlight())
    }
}

// MARK: - Preview

#Preview {
    MenuBarPanel(checkForUpdates: {})
        .environment(MatchStore())
}
