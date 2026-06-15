import SwiftUI

/// The `.window`-style panel shown when the menu bar item is clicked.
/// Glass-material design with tabbed navigation for Today, Yesterday, Tomorrow, Schedule, Standings.
struct MenuBarPanel: View {
    @Environment(MatchStore.self) private var store

    @State private var selectedTab: PanelTab = .today
    @State private var hasAppeared = false

    // Schedule state
    @State private var selectedScheduleDate: Date = Calendar.current.startOfDay(for: Date())
    @State private var scheduleMatches: [Match] = []
    @State private var isLoadingSchedule = false

    // Favorites state
    @State private var favoriteTeamSearch: String = ""

    // Animation state
    @State private var livePulse: Bool = false

    enum PanelTab: String, CaseIterable {
        case today = "Today"
        case yesterday = "Yesterday"
        case tomorrow = "Tomorrow"
        case fullSchedule = "Schedule"
        case standings = "Standings"
        case settings = "⚙️"
    }

    /// The 12 most popular / likely favorite teams (top nations by FIFA ranking + fanbase)
    private static let popularTeams: [String] = [
        "BRA", "ARG", "FRA", "GER", "ESP", "ENG",
        "NED", "POR", "ITA", "JPN", "MAR", "USA"
    ]

    /// Teams to show in the favorites grid — popular or search-filtered
    private var teamsToShow: [String] {
        if favoriteTeamSearch.isEmpty {
            return Self.popularTeams
        }
        let query = favoriteTeamSearch.uppercased()
        return Array(TeamFlags.flags.keys
            .filter { $0.contains(query) || (TeamFlags.flags[$0] ?? "").contains(query) }
            .sorted()
            .prefix(12))
    }

    /// 3-column grid layout for team pills
    private let favoriteGridColumns = [
        GridItem(.flexible(), spacing: 4),
        GridItem(.flexible(), spacing: 4),
        GridItem(.flexible(), spacing: 4)
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            Divider().opacity(0.4)
            tabRow
            Divider().opacity(0.3)
            content
                .layoutPriority(-1)
            Divider().opacity(0.4)
            footer
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 12)
        .frame(width: 360)
        .frame(maxHeight: 520)
        .background(.ultraThinMaterial, ignoresSafeAreaEdges: .all)
        .onAppear {
            if !hasAppeared {
                hasAppeared = true
                if !store.hasApiKey {
                    selectedTab = .settings
                }
            }
        }
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
                    HStack(spacing: 4) {
                        ProgressView().controlSize(.mini)
                        Text("Syncing…")
                    }
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                } else if let error = store.errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                        .lineLimit(1)
                } else if let match = store.featuredMatch, match.isLive {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(.red)
                            .frame(width: 6, height: 6)
                            .opacity(livePulse ? 1.0 : 0.3)
                        Text("LIVE")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.red)
                    }
                    .onAppear {
                        withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                            livePulse = true
                        }
                    }
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
                            .padding(.vertical, 5)
                            .background(
                                Capsule()
                                    .fill(selectedTab == tab
                                          ? Color.accentColor
                                          : Color.primary.opacity(0.06))
                            )
                            .foregroundStyle(selectedTab == tab ? .white : .secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
        }
        .scrollIndicators(.hidden)
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
                let matchContent = VStack(spacing: 6) {
                    // Live matches first
                    let live = matches.filter { $0.isLive }
                    if !live.isEmpty {
                        ForEach(live) { match in
                            MatchCard(match: match, isLiveHighlight: true)
                        }
                    }

                    // Upcoming matches (sorted by time)
                    let upcoming = matches
                        .filter { !$0.effectiveStatus.hasStarted }
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
                        ForEach(finished) { match in
                            MatchCard(match: match, isLiveHighlight: false)
                        }
                    }
                }

                if matches.count > 4 {
                    // Many matches — scrollable
                    ScrollView {
                        matchContent
                            .padding(.vertical, 6)
                    }
                    .scrollIndicators(.hidden)
                } else {
                    // Few matches — size to content, no scroll
                    matchContent
                        .padding(.vertical, 6)
                }
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
                .scrollIndicators(.hidden)
            }
        }
        .padding(.horizontal, 8)
    }

    // MARK: - Settings

    private var settingsView: some View {
        ScrollView(.vertical, showsIndicators: false) {
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
                        .font(.caption2)
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

            // Favorite team — 12 popular teams + search
            VStack(alignment: .leading, spacing: 6) {
                Text("Favorite Team")
                    .font(.caption.weight(.medium))

                Text("Prioritized in menu bar when upcoming")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)

                // Search field for TLA
                HStack(spacing: 4) {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.tertiary)
                        .font(.caption2)
                    TextField("Search team (e.g. KOR, MEX)…", text: $favoriteTeamSearch)
                        .textFieldStyle(.plain)
                        .font(.caption2)
                    if !favoriteTeamSearch.isEmpty {
                        Button {
                            favoriteTeamSearch = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.tertiary)
                                .font(.caption2)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.primary.opacity(0.06))
                )

                // None button
                Button {
                    store.favoriteTeam = nil
                } label: {
                    Text("None")
                        .font(.caption2)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(store.favoriteTeam == nil
                                      ? Color.accentColor
                                      : Color.primary.opacity(0.06))
                        )
                        .foregroundStyle(store.favoriteTeam == nil ? .white : .secondary)
                }
                .buttonStyle(.plain)

                // 3-column grid of team pills
                LazyVGrid(columns: favoriteGridColumns, spacing: 4) {
                    ForEach(teamsToShow, id: \.self) { tla in
                        Button {
                            store.favoriteTeam = tla
                        } label: {
                            Text("\(TeamFlags.flags[tla] ?? "⚽") \(tla)")
                                .font(.caption2)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 4)
                                .frame(maxWidth: .infinity)
                                .background(
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(store.favoriteTeam == tla
                                              ? Color.accentColor
                                              : Color.primary.opacity(0.06))
                                )
                                .foregroundStyle(store.favoriteTeam == tla ? .white : .secondary)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            Divider().opacity(0.3)

            // Version status
            let appVersion = Bundle.main.object(
                forInfoDictionaryKey: "CFBundleShortVersionString"
            ) as? String
            HStack {
                Text("FIFAWC Scores v\(appVersion ?? "?")")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                Spacer()
                Text("latest")
                    .font(.caption2)
                    .foregroundStyle(.green)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        }
        .scrollIndicators(.hidden)
    }

    // MARK: - Full Schedule

    private var fullScheduleView: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Day pills — horizontal scrollable row of date capsules
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(scheduleDateRange, id: \.self) { date in
                        let isSelected = Calendar.current.isDate(date, inSameDayAs: selectedScheduleDate)
                        let dayName = scheduleDayFormatter.string(from: date)
                        let dayNum = scheduleDayNumberFormatter.string(from: date)

                        Button {
                            withAnimation(.easeInOut(duration: 0.15)) {
                                selectedScheduleDate = date
                            }
                            Task {
                                await loadScheduleForDate(date)
                            }
                        } label: {
                            VStack(spacing: 2) {
                                Text(dayName)
                                    .font(.system(size: 9, weight: .medium))
                                Text(dayNum)
                                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                            }
                            .frame(width: 42)
                            .padding(.vertical, 6)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(isSelected
                                          ? Color.accentColor
                                          : Color.primary.opacity(0.06))
                            )
                            .foregroundStyle(isSelected ? .white : .secondary)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 8)
                .padding(.top, 6)
            }
        .scrollIndicators(.hidden)
            if isLoadingSchedule {
                VStack(spacing: 8) {
                    ProgressView()
                    Text("Loading matches…")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                .frame(maxWidth: .infinity, minHeight: 120)
            } else if scheduleMatches.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "calendar.badge.exclamationmark")
                        .font(.title2)
                        .foregroundStyle(.tertiary)
                    Text("No matches on this day")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, minHeight: 120)
            } else {
                let scheduleContent = VStack(spacing: 6) {
                    ForEach(scheduleMatches) { match in
                        MatchCard(match: match, isLiveHighlight: match.isLive)
                    }
                }
                if scheduleMatches.count > 4 {
                    ScrollView {
                        scheduleContent
                            .padding(.horizontal, 8)
                            .padding(.vertical, 6)
                    }
                    .scrollIndicators(.hidden)
                } else {
                    scheduleContent
                        .padding(.horizontal, 8)
                        .padding(.vertical, 6)
                }
            }
        }
        .task {
            await loadScheduleForDate(selectedScheduleDate)
        }
    }

    /// Range of dates for the day pills: today ± 14 days
    private var scheduleDateRange: [Date] {
        let cal = Calendar.current
        let start = cal.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        let end = cal.date(byAdding: .day, value: 7, to: Date()) ?? Date()
        var dates: [Date] = []
        var current = cal.startOfDay(for: start)
        while current <= cal.startOfDay(for: end) {
            dates.append(current)
            current = cal.date(byAdding: .day, value: 1, to: current) ?? current
        }
        return dates
    }

    private var scheduleDayFormatter: DateFormatter {
        let f = DateFormatter()
        f.dateFormat = "EEE"
        return f
    }

    private var scheduleDayNumberFormatter: DateFormatter {
        let f = DateFormatter()
        f.dateFormat = "d"
        return f
    }

    /// Load schedule matches around a date (±7 days) — uses MatchStore method
    private func loadScheduleForDate(_ date: Date) async {
        isLoadingSchedule = true

        // If we already have matches stored for this date, show them immediately
        let key = dateStringForSchedule(date)
        if let existing = store.matchesByDate[key] {
            scheduleMatches = existing
        }

        // Fetch ±7 days around the date
        await store.fetchScheduleAround(date)

        // Refresh from store after fetch
        let updated = store.matchesByDate[key] ?? []
        scheduleMatches = updated

        isLoadingSchedule = false
    }

    // MARK: - Footer

    private var footer: some View {
        VStack(spacing: 1) {
            Button {
                withAnimation(.easeInOut(duration: 0.15)) {
                    selectedTab = .settings
                }
            } label: {
                Label("Settings", systemImage: "gearshape")
                    .font(.caption.weight(.medium))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 5)
                    .padding(.horizontal, 8)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .menuRowHighlight()

            Button {
                Task { await store.sync() }
            } label: {
                HStack {
                    if store.isFetching {
                        ProgressView().controlSize(.mini)
                    } else {
                        Image(systemName: "arrow.triangle.2.circlepath")
                    }
                    Text("Sync")
                }
                .font(.caption.weight(.medium))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 5)
                .padding(.horizontal, 8)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .menuRowHighlight()
            .disabled(store.isFetching)

            #if DEBUG
            Button {
                store.triggerGoal()
            } label: {
                Label("Test Goal ⚽", systemImage: "flame")
                    .font(.caption.weight(.medium))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 5)
                    .padding(.horizontal, 8)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .menuRowHighlight()
            #endif

            Button { NSApplication.shared.terminate(nil) } label: {
                Label("Quit", systemImage: "power")
                    .font(.caption.weight(.medium))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 5)
                    .padding(.horizontal, 8)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .menuRowHighlight()
        }
        .padding(.top, 4)
    }

    // MARK: - Date Helpers

    private func dateStringForSchedule(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone.current  // Local timezone for correct tab grouping
        return formatter.string(from: date)
    }
}

// MARK: - Match Card

/// A glass card showing one match with flags, scores, status, and group.
struct MatchCard: View {
    let match: Match
    let isLiveHighlight: Bool

    @State private var scorePulse: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            // Main row: flags + teams + score/time
            HStack(spacing: 0) {
                // Home team
                HStack(spacing: 4) {
                    Text(match.homeTeam.flagEmoji)
                        .font(.system(size: 15))
                    Text(match.homeTeam.tla)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(isLiveHighlight ? TeamColors.forTeam(match.homeTeam.tla).primary : .primary)
                }
                .frame(minWidth: 60, alignment: .leading)

                Spacer()

                // Score or time
                Text(match.displayText)
                    .font(.system(.callout, design: .monospaced).weight(.bold))
                    .foregroundStyle(isLiveHighlight ? .red : .primary)
                    .contentTransition(.numericText())

                Spacer()

                // Away team
                HStack(spacing: 4) {
                    Text(match.awayTeam.tla)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(isLiveHighlight ? TeamColors.forTeam(match.awayTeam.tla).primary : .primary)
                    Text(match.awayTeam.flagEmoji)
                        .font(.system(size: 15))
                }
                .frame(minWidth: 60, alignment: .trailing)
            }

            // Status row: minute/status + group + venue
            HStack {
                if match.isLive {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(.red)
                            .frame(width: 5, height: 5)
                            .opacity(scorePulse ? 1.0 : 0.3)
                        Text(match.effectiveStatus.displayName)
                            .foregroundStyle(.red)
                            .font(.caption2.weight(.medium))
                    }
                    .onAppear {
                        withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                            scorePulse = true
                        }
                    }
                } else if match.isFinished {
                    Text("FT")
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(.secondary)
                } else {
                    HStack(spacing: 2) {
                        Image(systemName: "clock")
                            .font(.system(size: 8))
                        Text(match.effectiveStatus.displayName)
                    }
                    .font(.caption2)
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
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(.regularMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(isLiveHighlight
                              ? TeamColors.forTeam(match.homeTeam.tla).primary.opacity(0.06)
                              : Color.clear)
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isLiveHighlight
                        ? TeamColors.forTeam(match.homeTeam.tla).primary.opacity(0.2)
                        : Color.clear, lineWidth: 0.5)
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
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(.regularMaterial)
        )
    }
}

// MARK: - Menu Row Highlight

private struct MenuRowHighlight: ViewModifier {
    @State private var hovering = false

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(hovering ? Color.primary.opacity(0.08) : Color.clear)
            )
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
    MenuBarPanel()
        .environment(MatchStore())
}
