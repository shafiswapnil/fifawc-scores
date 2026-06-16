# Development Plan — FIFAWC Scores

## Milestones

### M1: Project Scaffolding

- Initialize project with XcodeGen (`project.yml`)
- Create directory structure (`Sources/`, `Tests/`)
- Configure Info.plist (`LSUIElement = true`)
- Build & run empty menu bar app
- Verify no Dock icon

### M2: Data Models

- `Match` — id, homeTeam, awayTeam, scores, status, venue, kickoff, group, matchday
- `Team` — id, name, shortName, flag emoji
- `Standing` — group, position, team, played, won, drawn, lost, goalDiff, points
- `MatchStatus` — enum (scheduled, timed, in_play, paused, finished, postponed, cancelled)
- `TeamColors` — hardcoded dictionary of team → primary/secondary colors

### M3: API Client (FetchService)

- `URLSession`-based client for football-data.org
- Endpoints: matches by date range, standings
- Free-tier rate limiting (10 req/min) — built-in request queue
- Response decoding (`Codable`)
- Error handling (network errors, API errors, rate limits)

### M4: MatchStore (Central State)

- `@Observable` class driving all views
- Holds today's, yesterday's, tomorrow's, and full tournament matches
- Holds group standings
- Provides computed properties for "next match", "live matches", "featured match"
- Day-rollover detection

### M5: PollController (Scheduling)

- Timer-based polling logic
- State machine: idle → scheduled → live → idle
- Configurable interval (default 60s, min 60s)
- Midnight auto-check for next day's matches
- Pause when no live matches
- Manual sync trigger

### M6: MenuBarLabel

- Compact menu bar view with five states:
  - Idle: `⚽ FWC` (no data or no match today)
  - Upcoming: `⚽ ESP vs CPV · 10:00 PM` (today only)
  - Live: `⚽ ESP 1-0 CPV · 67'`
  - Half-time: `⚽ ESP 1-0 CPV · HT`
  - Finished: `⚽ SWE 5-1 TUN · FT`
- Icon: `Image(systemName: "soccerball")` SF Symbol (emoji as `Text` consumed full status item width)
- Live minute counter ticks every 60s via `store.minuteTick: Date` (Task.sleep loop on MatchStore)
- `TimelineView` explicitly NOT used — hangs MenuBarExtra label on macOS
- `featuredMatch` priority: live → today-upcoming → recent-finished (never future days)
- `allMatches` scoped to 3-day window to prevent Schedule tab data bleeding in

### M7: Goal Animation

- Score change detection via `detectGoals()` on MatchStore
- `triggerGoal()` public method: sets `goalScored = true`, schedules 5s Task reset
- Menu bar label text flips to `GOAL!` for 5 seconds, then auto-reverts to score
- Sliding emoji animation dropped — all animation modifiers (`.symbolEffect`, `.scaleEffect`, offset/opacity overlays) fail silently inside MenuBarExtra label

### M8: MenuBarPanel

- Tabbed layout: Today | Yesterday | Tomorrow | Full Schedule | Standings
- Match cards with flags, scores, status
- Date navigation for Full Schedule
- Group standings tables
- Footer: Sync button, Settings, Quit
- Dynamic team-color theming

### M9: Settings (In-Panel)

- Poll interval slider (60s–300s)
- Favorite team picker
- Persisted in `UserDefaults` via `@AppStorage`

### M10: Polish & Testing

- Memory profiling (< 20 MB target)
- CPU profiling (< 1% during live)
- Edge cases: no matches, API errors, network offline
- Accessibility (VoiceOver labels)
- Conventional commit history

### M11: API Key in Settings (User-Configurable)

- `FetchService.apiKey` changed from `let` → `var` with `updateApiKey()` method
- `MatchStore.apiKey` persisted in UserDefaults via `@AppStorage`
- `MatchStore.fetchService` changed from `let` → `var` (re-creatable)
- `fetchAllData()` shows "No API key set — go to Settings" when key is missing
- Settings tab: API key text field + football-data.org registration link
- Green/orange status indicator (checkmark/warning)
- Added `FetchError.invalidAPIKey` case

### M12: Full Schedule Tab

- New `fullSchedule` case in `PanelTab` enum (labeled "Schedule")
- Date picker to filter matches from a start date onward
- Matches grouped by date with day headers (e.g., "Thu, Jun 11")
- Uses `store.allMatches` (all fetched dates)

### M13: TeamColors SRB Fix

- Removed duplicate `"SRB"` entry in `TeamColors.swift`

### M14: README.md

- Industry-standard README with centered header, badges, features list
- Build-from-source instructions (XcodeGen)
- API key setup guide, settings reference, architecture diagram

### M15: Auto-Update via Sparkle

- Add **Sparkle** via Swift Package Manager (SPM) — the industry-standard
  macOS update framework (used by VS Code, Discord, Rectangle, etc.)
- Add `SPUStandardUpdaterController` to `FIFAWCScoresApp`
- Add **"Check for Updates"** button in Settings tab
- Configure Sparkle feed URL → GitHub Releases API:
  `https://api.github.com/repos/{owner}/fifawc-scores/releases/latest`
- Sparkle handles: version comparison, download, Ed25519 signature
  verification, app replacement, and restart
- Add `SUFeedURL` to `Info.plist` pointing to GitHub Releases
- Update `CLAUDE.md` to note Sparkle as the one allowed third-party
  dependency (it's a framework, not a bloated library)

**Version consistency is critical:**

- `MARKETING_VERSION` in `project.yml` must match the git tag
  (e.g. tag `v1.1.0` → `MARKETING_VERSION: "1.1.0"`)
- Sparkle compares `CFBundleShortVersionString` (from `MARKETING_VERSION`)
  against the GitHub release tag to determine if an update is available

### M16: GitHub Actions CI/CD Pipeline

- Create `.github/workflows/release.yml`
- **Trigger:** push of a version tag (`v*`)
- **Jobs:**
  1. **Test** — `swiftc -parse` all sources, validate no warnings
  2. **Build** — `xcodebuild` on `macos-14` runner, produce `.app` bundle
  3. **Archive** — create `.zip` from `.app`
  4. **Sign** — codesign with Developer ID certificate (stored as
     GitHub Secrets: `DEVELOPER_ID_CERTIFICATE`, `CERTIFICATE_PASSWORD`)
  5. **Notarize** — submit to Apple via `notarytool` (secrets:
     `APPLE_ID`, `APPLE_TEAM_ID`, `NOTARIZATION_PASSWORD`)
  6. **Staple** — staple the notarization ticket to the `.app`
  7. **Release** — create GitHub Release with `.zip` attached, auto-generate
     release notes from commit messages
- Create `.github/workflows/ci.yml` for PR checks (parse + build)

**GitHub Secrets required:**
| Secret | Purpose |
|--------|---------|
| `DEVELOPER_ID_CERTIFICATE` | Base64-encoded .p12 certificate |
| `CERTIFICATE_PASSWORD` | Password for the .p12 |
| `APPLE_ID` | Apple ID for notarization |
| `APPLE_TEAM_ID` | Apple Developer Team ID |
| `NOTARIZATION_PASSWORD` | App-specific password for notarization |

### M17: Version Management Script

- Create `scripts/bump-version.sh`
- Usage: `./scripts/bump-version.sh 1.1.0`
- Actions:
  1. Update `MARKETING_VERSION` in `project.yml`
  2. Run `xcodegen generate` to regenerate project
  3. Validate version format (semver)
  4. Create git commit: `chore: bump version to 1.1.0`
  5. Create git tag: `v1.1.0`
  6. Print: `git push origin main --tags` reminder
- CI enforces: tag version must match `MARKETING_VERSION` in `project.yml`

### M18: Test Suite

- Create `Tests/` directory with XCTest targets
- Unit tests for:
  - **FetchService** — URL construction, rate limiter, error handling
  - **MatchStore** — goal detection logic, computed properties, API key
    guard (empty key shows error, valid key allows fetch)
  - **Match model** — Codable round-trip, computed properties (isLive,
    isFinished, displayText, homeScore, awayScore)
  - **MatchStatus** — displayName, isLive, hasStarted for each case
- CI runs tests before publishing (gates the release pipeline)
- Add `FIFAWCScoreTests` target to `project.yml`

---

## Build Order

```
M1 → M2 → M3 → M4 → M5 → M6 → M7 → M8 → M9 → M10 → M11 → M12 → M13 → M14
                                                                          ↓
M15 ← M16 ← M17 ← M18 (auto-update + CI/CD phase, can be done in parallel)
```

**Phase 1 (M1–M14):** App features — ✅ DONE
**Phase 2 (M15–M18):** Distribution & update infrastructure

Each milestone is independently buildable and testable.
