import Foundation

/// Central observable state for the entire app.
/// Drives the menu bar label, panel, and all views.
/// Owns the poll controller and coordinates data fetching.
///
/// Isolated to `@MainActor` because it holds all UI state and is
/// observed by SwiftUI views. The PollController is a plain class
/// (not an actor) — all access is main-actor-isolated.
@MainActor
@Observable
final class MatchStore {

    // MARK: - Match Data

    /// Matches grouped by date (YYYY-MM-DD string key).
    private(set) var matchesByDate: [String: [Match]] = [:]

    /// Group standings (all groups A–H).
    private(set) var standings: [GroupStanding] = []

    // MARK: - UI State

    /// The last time data was successfully fetched.
    private(set) var lastFetchTime: Date?

    /// Current error message, if any. Cleared on next successful fetch.
    private(set) var errorMessage: String?

    /// Whether a fetch is currently in progress.
    private(set) var isFetching = false

    /// Goal animation trigger. Set when a score change is detected.
    var goalScored = false

    /// Ticks every 60 s so MenuBarLabel re-renders the live minute counter.
    /// Updated by a lightweight Task loop started in startPolling().
    /// This is the @Observable alternative to TimelineView (which hangs in
    /// MenuBarExtra label context on macOS).
    private(set) var minuteTick: Date = .now

    // MARK: - Polling

    private var pollController: PollController?
    private var fetchService: FetchService
    private var tickTask: Task<Void, Never>?

    // MARK: - Settings (persisted)

    /// Polling interval in seconds. Minimum 60.
    /// Uses a private backing store to avoid @Observable + didSet recursion.
    private var _pollInterval: TimeInterval = 60
    var pollInterval: TimeInterval {
        get { _pollInterval }
        set {
            let clamped = max(60, newValue)
            guard clamped != _pollInterval else { return }
            _pollInterval = clamped
            UserDefaults.standard.set(clamped, forKey: "pollInterval")
            pollController?.updateInterval(clamped)
        }
    }

    /// Favorite team TLA (e.g. "BRA"). Optional.
    var favoriteTeam: String? {
        didSet {
            if let team = favoriteTeam {
                UserDefaults.standard.set(team, forKey: "favoriteTeam")
            } else {
                UserDefaults.standard.removeObject(forKey: "favoriteTeam")
            }
        }
    }

    /// API key for football-data.org. Persisted in UserDefaults.
    /// Empty string means not configured — app shows error and won't poll.
    var apiKey: String {
        didSet {
            UserDefaults.standard.set(apiKey, forKey: "apiKey")
            Task { await fetchService.updateApiKey(apiKey) }
        }
    }

    /// Whether a valid API key has been configured.
    var hasApiKey: Bool {
        !apiKey.trimmingCharacters(in: .whitespaces).isEmpty
    }

    // MARK: - Previous Scores (for goal detection)

    private var previousScores: [Int: ScoreSnapshot] = [:]

    /// Simple struct for previous score tracking (tuples aren't Sendable).
    private struct ScoreSnapshot {
        let home: Int?
        let away: Int?
    }

    // MARK: - Init

    init() {
        // Restore settings from UserDefaults
        let storedInterval = UserDefaults.standard.double(forKey: "pollInterval")
        self._pollInterval = storedInterval > 0 ? max(60, storedInterval) : 60
        self.favoriteTeam = UserDefaults.standard.string(forKey: "favoriteTeam")

        let storedApiKey = UserDefaults.standard.string(forKey: "apiKey") ?? ""
        self.apiKey = storedApiKey
        self.fetchService = FetchService(apiKey: storedApiKey)
    }

    // MARK: - Computed Properties

    /// Today's date string (UTC) for matching.
    var todayKey: String {
        dateString(for: Date())
    }

    /// Yesterday's date string (UTC).
    var yesterdayKey: String {
        dateString(for: Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date())
    }

    /// Tomorrow's date string (UTC).
    var tomorrowKey: String {
        dateString(for: Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date())
    }

    /// Matches for today.
    var todayMatches: [Match] {
        matchesByDate[todayKey] ?? []
    }

    /// Matches for yesterday.
    var yesterdayMatches: [Match] {
        matchesByDate[yesterdayKey] ?? []
    }

    /// Matches for tomorrow.
    var tomorrowMatches: [Match] {
        matchesByDate[tomorrowKey] ?? []
    }

    /// Core matches: yesterday + today + tomorrow only, sorted newest first.
    /// Intentionally scoped to the 3-day window so that Schedule tab data
    /// (written into matchesByDate via fetchScheduleAround) never bleeds
    /// into featuredMatch, liveMatches, or any other core logic.
    /// The Schedule tab reads matchesByDate[key] directly and is unaffected.
    var allMatches: [Match] {
        [yesterdayKey, todayKey, tomorrowKey]
            .flatMap { matchesByDate[$0] ?? [] }
            .sorted { $0.utcDate > $1.utcDate }
    }

    /// Currently live matches, sorted by elapsed time (most elapsed first).
    var liveMatches: [Match] {
        allMatches.filter { $0.isLive }.sorted { $0.utcDate < $1.utcDate }
    }

    /// Whether any matches are currently live.
    var hasLiveMatches: Bool {
        !liveMatches.isEmpty
    }

    /// The next upcoming match (closest to now, not yet started).
    /// If a favorite team is set, prioritizes that match.
    var nextMatch: Match? {
        let now = Date()
        let upcoming = allMatches.filter {
            !$0.effectiveStatus.hasStarted && $0.utcDate > now
        }.sorted { $0.utcDate < $1.utcDate }

        if let fav = favoriteTeam {
            if let favMatch = upcoming.first(where: {
                $0.homeTeam.tla == fav || $0.awayTeam.tla == fav
            }) {
                return favMatch
            }
        }
        return upcoming.first
    }

    /// The "featured" match — the one shown in the menu bar label.
    ///
    /// Priority:
    /// 1. Live match (most elapsed first)
    /// 2. Next upcoming match **today only** — never shows tomorrow/future
    /// 3. Most recent finished match (any day)
    /// 4. nil → label shows idle "FWC"
    var featuredMatch: Match? {
        // 1. Live
        if let live = liveMatches.first { return live }

        // 2. Soonest upcoming match TODAY only
        let now = Date()
        let todayUpcoming = todayMatches
            .filter { !$0.effectiveStatus.hasStarted && $0.utcDate > now }
            .sorted { $0.utcDate < $1.utcDate }
        if let next = todayUpcoming.first { return next }

        // 3. Most recent finished (today first, then older)
        return allMatches
            .filter { $0.isFinished }
            .sorted { $0.utcDate > $1.utcDate }
            .first
    }

    /// Upcoming matches sorted by kickoff time (soonest first), limited to today.
    var upcomingToday: [Match] {
        let now = Date()
        return todayMatches
            .filter { !$0.effectiveStatus.hasStarted && $0.utcDate > now }
            .sorted { $0.utcDate < $1.utcDate }
    }

    /// Finished matches from today, most recent first.
    var finishedToday: [Match] {
        todayMatches
            .filter { $0.isFinished }
            .sorted { $0.utcDate > $1.utcDate }
    }

    // MARK: - Public API

    /// Start the poll controller. Call once after init.
    func startPolling() {
        guard pollController == nil else { return }
        let controller = PollController(store: self, interval: pollInterval)
        self.pollController = controller
        controller.start()
        startMinuteTicker()
    }

    /// Stop polling.
    func stopPolling() {
        pollController?.stop()
        pollController = nil
        tickTask?.cancel()
        tickTask = nil
    }

    /// Fires every 60 s to update minuteTick, causing MenuBarLabel to
    /// re-render the live elapsed-minute counter in real time.
    private func startMinuteTicker() {
        guard tickTask == nil else { return }
        tickTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(60))
                guard !Task.isCancelled else { break }
                self?.minuteTick = .now
            }
        }
    }

    /// Trigger goal animation. Sets goalScored = true and auto-resets after 2 s.
    func triggerGoal() {
        goalScored = true
        Task { [weak self] in
            try? await Task.sleep(for: .seconds(2.0))
            self?.goalScored = false
        }
    }

    /// Force an immediate data fetch (manual sync).
    func sync() async {
        await fetchAllData()
    }

    /// Fetch matches for the schedule tab (±7 days around a date).
    /// Called when user picks a date in the Schedule tab.
    func fetchScheduleAround(_ date: Date) async {
        guard hasApiKey else { return }

        let cal = Calendar.current
        guard let startDate = cal.date(byAdding: .day, value: -7, to: date),
              let endDate = cal.date(byAdding: .day, value: 7, to: date) else { return }

        do {
            let matches = try await fetchService.fetchMatches(from: startDate, to: endDate)

            var grouped: [String: [Match]] = [:]
            for match in matches {
                let key = dateString(for: match.utcDate)
                grouped[key, default: []].append(match)
            }

            for (key, dayMatches) in grouped {
                matchesByDate[key] = dayMatches.sorted { $0.utcDate < $1.utcDate }
            }

            detectGoals(newMatches: matches)
        } catch {
            // Silent fail for schedule — don't overwrite main error
        }
    }

    // MARK: - Data Fetching

    /// Fetch all needed data: today, yesterday, tomorrow matches + standings.
    func fetchAllData() async {
        guard !isFetching else { return }

        guard hasApiKey else {
            errorMessage = "No API key set — go to Settings"
            return
        }

        isFetching = true
        errorMessage = nil

        do {
            let cal = Calendar.current
            let yesterday = cal.date(byAdding: .day, value: -1, to: Date()) ?? Date()
            let tomorrow = cal.date(byAdding: .day, value: 1, to: Date()) ?? Date()

            async let matchesTask = fetchService.fetchMatches(from: yesterday, to: tomorrow)
            async let standingsTask = fetchService.fetchStandings()

            let (matches, newStandings) = try await (matchesTask, standingsTask)

            // Group matches by date
            var grouped: [String: [Match]] = [:]
            for match in matches {
                let key = dateString(for: match.utcDate)
                grouped[key, default: []].append(match)
            }

            // Merge with existing data
            for (key, dayMatches) in grouped {
                matchesByDate[key] = dayMatches.sorted { $0.utcDate < $1.utcDate }
            }

            // Detect goals before updating standings
            detectGoals(newMatches: matches)

            standings = newStandings
            lastFetchTime = Date()

        } catch {
            errorMessage = (error as? FetchError)?.errorDescription ?? error.localizedDescription
        }

        isFetching = false
    }

    // MARK: - Goal Detection

    /// Compare new scores against previous scores to detect goals.
    private func detectGoals(newMatches: [Match]) {
        for match in newMatches where match.isLive || match.isFinished {
            let newHome = match.homeScore
            let newAway = match.awayScore

            if let prev = previousScores[match.id] {
                let homeScored = (newHome ?? 0) > (prev.home ?? 0)
                let awayScored = (newAway ?? 0) > (prev.away ?? 0)

                if homeScored || awayScored {
                    triggerGoal()
                }
            }

            // Store current scores for next comparison
            previousScores[match.id] = ScoreSnapshot(home: newHome, away: newAway)
        }
    }

    // MARK: - Helpers

    private func dateString(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone.current  // User's local timezone for correct tab grouping
        return formatter.string(from: date)
    }
}
