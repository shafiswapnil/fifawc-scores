import Foundation

/// Polling interval state — used by MatchStore to determine the right polling behavior.
enum PollState: Equatable {
    /// No live matches. Poll periodically to catch TIMED→IN_PLAY transitions.
    case idle
    /// Matches in progress. Poll at configured interval.
    case live
    /// Polling paused.
    case paused
}

/// Timer-based polling controller.
/// Drives `MatchStore` to fetch data at appropriate intervals.
///
/// Runs on `@MainActor` to directly access `MatchStore` (which is also
/// `@MainActor`). Uses `Task.sleep` for timing — no DispatchTimers or
/// RunLoops needed.
@MainActor
final class PollController {

    // MARK: - Dependencies

    private weak var store: MatchStore?

    // MARK: - Configuration

    /// Polling interval for live matches (in seconds).
    private var interval: TimeInterval

    /// Minimum allowed interval (per spec: 60 seconds).
    private let minInterval: TimeInterval = 60

    // MARK: - State

    private var state: PollState = .idle
    private var pollTask: Task<Void, Never>?

    // MARK: - Init

    init(store: MatchStore, interval: TimeInterval = 60) {
        self.store = store
        self.interval = max(minInterval, interval)
    }

    // MARK: - Public

    /// Start the poll controller. Initial fetch + determine state.
    func start() {
        guard pollTask == nil else { return }
        pollTask = Task { [weak self] in
            await self?.run()
        }
    }

    /// Stop all polling and timers.
    func stop() {
        pollTask?.cancel()
        pollTask = nil
        state = .idle
    }

    /// Update the polling interval. Respects minimum.
    func updateInterval(_ newInterval: TimeInterval) {
        interval = max(minInterval, newInterval)
    }

    /// Force an immediate poll (manual sync). Resets the current timer.
    func forcePoll() async {
        pollTask?.cancel()
        await store?.sync()
        updateState()
        pollTask = Task { [weak self] in
            await self?.run()
        }
    }

    // MARK: - Core Loop

    private func run() async {
        // Initial fetch
        await store?.sync()
        updateState()

        while !Task.isCancelled {
            switch state {
            case .idle:
                // Poll every 120 s in idle to catch TIMED → IN_PLAY transitions.
                // This is the key fix: we can't wait until midnight because we'd
                // miss any match that kicks off between now and then.
                try? await Task.sleep(for: .seconds(120))
                if Task.isCancelled { break }

                // Re-fetch data to catch status changes (TIMED→IN_PLAY, new day's matches)
                await store?.sync()
                updateState()

            case .live:
                // Wait the configured interval then re-fetch
                try? await Task.sleep(for: .seconds(interval))
                if Task.isCancelled { break }
                await store?.sync()
                updateState()

            case .paused:
                // Re-check every 60s in case state changed externally
                try? await Task.sleep(for: .seconds(60))
                if Task.isCancelled { break }
                updateState()
            }
        }
    }

    // MARK: - State Transitions

    /// Evaluate current data and transition to the appropriate state.
    private func updateState() {
        guard let store else { return }

        if store.hasLiveMatches {
            state = .live
        } else {
            state = .idle
        }
    }
}
