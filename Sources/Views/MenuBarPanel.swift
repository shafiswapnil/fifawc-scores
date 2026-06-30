import SwiftUI

/// The `.window`-style panel shown when the menu bar item is clicked.
/// v2 — Production-safe panel. Solid dark bg + DarkModeBridge for dark mode.
/// DarkModeBridge is safe here because there are NO material overlays —
/// just solid colors that work identically in Debug and Release builds.
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
            Divider().opacity(0.2)
            tabRow
            Divider().opacity(0.15)
            content
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            Divider().opacity(0.2)
            footer
        }
        .padding(.horizontal, 4)
        .padding(.top, 6)
        .padding(.bottom, 4)
        .frame(width: 380, height: 480)
        .background(Theme.panelBackground)
        .overlay(DarkModeBridge().allowsHitTesting(false))
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
                    .foregroundStyle(Theme.textSecondary)
                    .tracking(0.5)

                if store.isFetching {
                    HStack(spacing: 4) {
                        ProgressView().controlSize(.mini)
                        Text("Syncing…")
                    }
                    .font(.caption)
                    .foregroundStyle(Theme.textSecondary)
                } else if let error = store.errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                        .lineLimit(1)
                } else if let match = store.featuredMatch, match.isLive {
                    HStack(spacing: 5) {
                        Circle()
                            .fill(Theme.live)
                            .frame(width: 6, height: 6)
                            .opacity(livePulse ? 1.0 : 0.3)
                        Text("LIVE")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(Theme.live)
                    }
                    .onAppear {
                        withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                            livePulse = true
                        }
                    }
                } else {
                    HStack(spacing: 4) {
                        Image(systemName: "soccerball")
                        Text("Match Hub")
                    }
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(Theme.textPrimary)
                }
            }
            Spacer()
        }
        .padding(.horizontal, 8)
        .padding(.top, 10)
        .padding(.bottom, 8)
    }

    // MARK: - Tab Row (underline style)

    private var tabRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 4) {
                ForEach(PanelTab.allCases, id: \.self) { tab in
                    Button {
                        withAnimation(.easeInOut(duration: 0.15)) {
                            selectedTab = tab
                        }
                    } label: {
                        VStack(spacing: 0) {
                            Text(tab.rawValue)
                                .font(.caption.weight(.medium))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .foregroundStyle(selectedTab == tab ? Theme.orange : Theme.textSecondary)

                            // Underline indicator
                            RoundedRectangle(cornerRadius: 1)
                                .fill(selectedTab == tab ? Theme.orange : Color.clear)
                                .frame(height: 2)
                                .frame(width: 24)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.leading, 8)
            .padding(.trailing, 14)
            .padding(.vertical, 6)
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

    /// Sort matches into (live, upcoming, finished) buckets.
    private func bucketMatches(_ matches: [Match]) -> (live: [Match], upcoming: [Match], finished: [Match]) {
        let live = matches.filter { $0.isLive }
        let upcoming = matches.filter { !$0.effectiveStatus.hasStarted }.sorted { $0.utcDate < $1.utcDate }
        let finished = matches.filter { $0.isFinished }.sorted { $0.utcDate > $1.utcDate }
        return (live, upcoming, finished)
    }

    private func matchList(_ matches: [Match], emptyText: String) -> some View {
        Group {
            if matches.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "calendar")
                        .font(.title2)
                        .foregroundStyle(Theme.textSecondary)
                    Text(emptyText)
                        .font(.callout)
                        .foregroundStyle(Theme.textSecondary)
                }
                .frame(maxWidth: .infinity, minHeight: 120)
            } else {
                let fav = store.favoriteTeam
                let favSet = matches.filter { fav != nil && ($0.homeTeam.tla == fav || $0.awayTeam.tla == fav) }
                let otherSet = fav != nil ? matches.filter { $0.homeTeam.tla != fav && $0.awayTeam.tla != fav } : matches
                let favB = bucketMatches(favSet)
                let otherB = bucketMatches(otherSet)
                let hasFav = !favSet.isEmpty

                let matchContent = VStack(spacing: 6) {
                    // Fav team matches pinned to top
                    if hasFav {
                        ForEach(favB.live) { match in
                            MatchCard(match: match, isLiveHighlight: true, isFavoriteHighlight: true)
                        }
                        ForEach(favB.upcoming) { match in
                            MatchCard(match: match, isLiveHighlight: false, isFavoriteHighlight: true)
                        }
                        ForEach(favB.finished) { match in
                            MatchCard(match: match, isLiveHighlight: false, isFavoriteHighlight: true)
                        }
                    }

                    // Separator between fav and other sections
                    if hasFav && (!otherB.live.isEmpty || !otherB.upcoming.isEmpty || !otherB.finished.isEmpty) {
                        HStack(spacing: 6) {
                            Rectangle().fill(Theme.glassStroke).frame(height: 0.5)
                            Text("Other Matches")
                                .font(.caption2)
                                .foregroundStyle(Theme.textSecondary)
                            Rectangle().fill(Theme.glassStroke).frame(height: 0.5)
                        }
                        .padding(.vertical, 2)
                    }

                    // Other matches
                    ForEach(otherB.live) { match in
                        MatchCard(match: match, isLiveHighlight: true, isFavoriteHighlight: false)
                    }
                    ForEach(otherB.upcoming) { match in
                        MatchCard(match: match, isLiveHighlight: false, isFavoriteHighlight: false)
                    }
                    ForEach(otherB.finished) { match in
                        MatchCard(match: match, isLiveHighlight: false, isFavoriteHighlight: false)
                    }
                }

                if matches.count > 4 {
                    ScrollView {
                        matchContent
                            .padding(.vertical, 6)
                    }
                    .scrollIndicators(.hidden)
                } else {
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
                        .foregroundStyle(Theme.textSecondary)
                    Text("No standings available")
                        .font(.callout)
                        .foregroundStyle(Theme.textSecondary)
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
                            .foregroundStyle(Theme.textPrimary)
                        if store.hasApiKey {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                                .font(.caption2)
                        } else {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(Theme.orange)
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
                    .foregroundStyle(Theme.textSecondary)
                }

                Divider().opacity(0.2)

                // Poll interval
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Live Poll Interval")
                            .font(.caption.weight(.medium))
                            .foregroundStyle(Theme.textPrimary)
                        Spacer()
                        Text("\(Int(store.pollInterval))s")
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(Theme.textSecondary)
                    }
                    Slider(
                        value: Binding(
                            get: { store.pollInterval },
                            set: { store.pollInterval = $0 }
                        ),
                        in: 60...300,
                        step: 30
                    )
                    .tint(Theme.orange)
                    Text("Min 60s · Higher = less API usage")
                        .font(.caption2)
                        .foregroundStyle(Theme.textSecondary)
                }

                Divider().opacity(0.2)

                // Favorite team — 12 popular teams + search
                VStack(alignment: .leading, spacing: 6) {
                    Text("Favorite Team")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(Theme.textPrimary)

                    Text("Prioritized in menu bar when upcoming")
                        .font(.caption2)
                        .foregroundStyle(Theme.textSecondary)

                    // Search field for TLA
                    HStack(spacing: 4) {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(Theme.textSecondary)
                            .font(.caption2)
                        TextField("Search team (e.g. KOR, MEX)…", text: $favoriteTeamSearch)
                            .textFieldStyle(.plain)
                            .font(.caption2)
                        if !favoriteTeamSearch.isEmpty {
                            Button {
                                favoriteTeamSearch = ""
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(Theme.textSecondary)
                                    .font(.caption2)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Theme.surfaceSubtle)
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(Theme.glassStroke, lineWidth: 0.5)
                            )
                    )

                    // None button — underline style like tabs
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
                                          ? Theme.orange
                                          : Theme.tabInactiveBackground)
                            )
                            .foregroundStyle(store.favoriteTeam == nil ? .white : Theme.textSecondary)
                    }
                    .buttonStyle(.plain)

                    // 3-column grid of team pills — glass border treatment
                    LazyVGrid(columns: favoriteGridColumns, spacing: 4) {
                        ForEach(teamsToShow, id: \.self) { tla in
                            Button {
                                store.favoriteTeam = tla
                            } label: {
                                Text("\(TeamFlags.flags[tla] ?? "🏳️") \(tla)")
                                    .font(.caption2)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 4)
                                    .frame(maxWidth: .infinity)
                                    .background(
                                        RoundedRectangle(cornerRadius: 6)
                                            .fill(store.favoriteTeam == tla
                                                  ? Theme.orange
                                                  : Theme.surfaceSubtle)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 6)
                                                    .stroke(store.favoriteTeam == tla
                                                            ? Theme.orange.opacity(0.4)
                                                            : Theme.glassStroke,
                                                            lineWidth: 0.5)
                                            )
                                    )
                                    .foregroundStyle(store.favoriteTeam == tla ? .white : Theme.textSecondary)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                Divider().opacity(0.2)

                // Version status
                let appVersion = Bundle.main.object(
                    forInfoDictionaryKey: "CFBundleShortVersionString"
                ) as? String
                HStack {
                    Text("FIFAWC Scores v\(appVersion ?? "?")")
                        .font(.caption2)
                        .foregroundStyle(Theme.textSecondary)
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
                                    .foregroundStyle(isSelected ? Theme.orange : Theme.textSecondary)
                                Text(dayNum)
                                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                                    .foregroundStyle(isSelected ? Theme.orange : Theme.textPrimary)
                            }
                            .frame(width: 42)
                            .padding(.vertical, 6)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(isSelected
                                          ? Theme.tabActiveBackground
                                          : Color.clear)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(isSelected ? Theme.orange.opacity(0.3) : Theme.glassStroke, lineWidth: 0.5)
                                    )
                            )
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
                        .foregroundStyle(Theme.textSecondary)
                }
                .frame(maxWidth: .infinity, minHeight: 120)
            } else if scheduleMatches.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "calendar.badge.exclamationmark")
                        .font(.title2)
                        .foregroundStyle(Theme.textSecondary)
                    Text("No matches on this day")
                        .font(.callout)
                        .foregroundStyle(Theme.textSecondary)
                }
                .frame(maxWidth: .infinity, minHeight: 120)
            } else {
                // Filter by favorite team if set
                let displayMatches: [Match] = {
                    guard let fav = store.favoriteTeam else { return scheduleMatches }
                    let filtered = scheduleMatches.filter { $0.homeTeam.tla == fav || $0.awayTeam.tla == fav }
                    return filtered.isEmpty ? scheduleMatches : filtered
                }()
                let scheduleContent = VStack(spacing: 6) {
                    ForEach(displayMatches) { match in
                        MatchCard(match: match, isLiveHighlight: match.isLive,
                                  isFavoriteHighlight: store.favoriteTeam != nil &&
                                    (match.homeTeam.tla == store.favoriteTeam || match.awayTeam.tla == store.favoriteTeam))
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

    /// Range of dates for the day pills: today ± 7 days
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

        let key = dateStringForSchedule(date)
        if let existing = store.matchesByDate[key] {
            scheduleMatches = existing
        }

        await store.fetchScheduleAround(date)

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
                    .foregroundStyle(Theme.textSecondary)
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
                .foregroundStyle(Theme.textSecondary)
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
                    .font(.caption.weight(.medium))
                    .foregroundStyle(Theme.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 5)
                    .padding(.horizontal, 8)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .menuRowHighlight()
        }
        .padding(.top, 4)
        .padding(.bottom, 10)
    }

    // MARK: - Date Helpers

    private func dateStringForSchedule(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone.current
        return formatter.string(from: date)
    }
}

// MARK: - Match Card

/// A card showing one match with flags, scores, status, and group.
/// Production-safe: solid dark fill, no material/glass assumptions.
struct MatchCard: View {
    let match: Match
    let isLiveHighlight: Bool
    let isFavoriteHighlight: Bool

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
                        .foregroundStyle(isLiveHighlight
                                         ? TeamColors.forTeam(match.homeTeam.tla).primary
                                         : Theme.textPrimary)
                }
                .frame(minWidth: 60, alignment: .leading)

                Spacer()

                // Score or time
                Text(match.displayText)
                    .font(.system(.callout, design: .monospaced).weight(.bold))
                    .foregroundStyle(isLiveHighlight ? Theme.orange : Theme.textPrimary)
                    .contentTransition(.numericText())

                Spacer()

                // Away team
                HStack(spacing: 4) {
                    Text(match.awayTeam.tla)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(isLiveHighlight
                                         ? TeamColors.forTeam(match.awayTeam.tla).primary
                                         : Theme.textPrimary)
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
                            .fill(Theme.orange)
                            .frame(width: 5, height: 5)
                            .opacity(scorePulse ? 1.0 : 0.3)
                        Text(match.effectiveStatus.displayName)
                            .foregroundStyle(Theme.orange)
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
                        .foregroundStyle(Theme.textSecondary)
                } else {
                    HStack(spacing: 2) {
                        Image(systemName: "clock")
                            .font(.system(size: 8))
                        Text(match.effectiveStatus.displayName)
                    }
                    .font(.caption2)
                    .foregroundStyle(Theme.textSecondary)
                }

                if let group = match.groupDisplay {
                    Text("·")
                    Text(group)
                }

                Spacer()

                if let venue = match.venue {
                    Text(venue)
                        .font(.caption2)
                        .foregroundStyle(Theme.textSecondary)
                        .lineLimit(1)
                }
            }
            .font(.caption2)
            .foregroundStyle(Theme.textSecondary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isFavoriteHighlight ? Theme.favHighlight : Theme.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(isFavoriteHighlight ? Theme.favBorder : Theme.glassStroke,
                                lineWidth: isFavoriteHighlight ? 1 : 0.5)
                )
        )
    }
}

// MARK: - Group Standing Card

/// A mini group table showing team positions, points, and goal difference.
/// Production-safe: solid dark card, no material/glass assumptions.
struct GroupStandingCard: View {
    let group: GroupStanding

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            // Group header
            Text(group.displayName)
                .font(.caption.weight(.semibold))
                .foregroundStyle(Theme.textSecondary)
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
            .foregroundStyle(Theme.textSecondary)
            .padding(.horizontal, 4)

            // Team rows
            ForEach(group.table) { entry in
                HStack(spacing: 0) {
                    Text("\(entry.position).")
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundStyle(Theme.textSecondary)
                        .frame(width: 16, alignment: .trailing)

                    Text(entry.team.flagEmoji)
                        .font(.system(size: 11))

                    Text(entry.team.tla)
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(Theme.textPrimary)
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
                                         : entry.goalDifference < 0 ? .red : Theme.textSecondary)
                    Text("\(entry.points)")
                        .frame(width: 28)
                        .fontWeight(.bold)
                        .foregroundStyle(Theme.textPrimary)
                }
                .font(.system(size: 10, design: .monospaced))
                .padding(.horizontal, 4)
                .padding(.vertical, 2)
                .background(entry.isQualified
                            ? Theme.qualifiedTint
                            : Color.clear)
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Theme.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Theme.glassStroke, lineWidth: 0.5)
                )
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
                    .fill(hovering ? Theme.tabActiveBackground : Color.clear)
            )
            .onHover { hovering = $0 }
    }
}

extension View {
    func menuRowHighlight() -> some View {
        modifier(MenuRowHighlight())
    }
}
