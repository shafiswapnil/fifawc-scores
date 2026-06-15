# Project Status — FIFAWC Scores

> This file tracks the current stage of the project for any agent or LLM
> working on it. Always update this file when milestones are completed.

## Current Stage

**Phase 1 complete (M1–M18). Phase 2 complete (M15–M18). Phase 3 complete (M19).** Full UI/UX redesign: glass material panel, 520px height, horizontal day pills, 12-team grid with search, live match experience with pulsing dot + team colors, hidden scrollbars, ±7 day schedule fetching. **Bug fixes**: PollController idle state now polls every 120s (was waiting until midnight). FetchService uses dedicated URLSession with no cache + Cache-Control: no-cache header (was using URLSession.shared which cached stale TIMED responses). **API compliance**: MatchStatus includes EXTRA_TIME + PENALTY_SHOOTOUT. Response-header-aware rate limiting (X-RequestsAvailable, X-RequestCounter-Reset). **CRITICAL FIX**: football-data.org free tier returns stale match status — API showed TIMED while match was actually LIVE for 32+ min. Implemented client-side status inference (`effectiveStatus`) that overrides stale API status using match clock logic (0–135 min after kickoff → infer IN_PLAY). **STABLE REVERT**: Reverted menu bar changes from Prompts 24–27 to restore panel stability. Menu bar label is now plain system default color (no team colors, no animations). **TIMEZONE FIX**: `dateString()` now uses local timezone for correct tab grouping. All tabs match Google's local date grouping. **PANEL HEIGHT**: Panel now shrinks to content when list is short (footer pulls up), caps at 520px when content exceeds. Schedule tab also fixed to use local timezone.

## Milestone Tracker

| #   | Milestone                   | Status  | Commit  | Notes                                                                                                           |
| --- | --------------------------- | ------- | ------- | --------------------------------------------------------------------------------------------------------------- |
| M1  | Project Scaffolding         | ✅ Done | 157f5f3 | XcodeGen, dirs, Info.plist, empty MenuBarExtra                                                                  |
| M2  | Data Models                 | ✅ Done | bced77f | Match, Team, Standing, MatchStatus, TeamColors                                                                  |
| M3  | API Client (FetchService)   | ✅ Done | 88a5c5a | football-data.org v4, URLSession, rate limiter                                                                  |
| M4  | MatchStore (Central State)  | ✅ Done | 102e099 | @Observable @MainActor, goal detection, computed props                                                          |
| M5  | PollController (Scheduling) | ✅ Done | 102e099 | State machine: idle→live→idle, midnight rollover                                                                |
| M6  | MenuBarLabel                | ✅ Done | 9a90463 | 3 states: idle/upcoming/live, dynamic team colors                                                               |
| M7  | Goal Animation              | ✅ Done | 9a90463 | ⚨ slide left→right (1.5s ease-in-out)                                                                           |
| M8  | MenuBarPanel                | ✅ Done | b310017 | Tabs, MatchCards, GroupStandingCards, footer                                                                    |
| M9  | Settings (In-Panel)         | ✅ Done | 2a19c7b | Poll interval slider, favorite team picker                                                                      |
| M10 | Polish & Testing            | ✅ Done | 0d5b386 | Cleaned duplicate TLA keys, all files compile clean                                                             |
| M11 | API Key in Settings         | ✅ Done | TBD     | UserDefaults storage, Settings UI, error in header                                                              |
| M12 | Full Schedule Tab           | ✅ Done | TBD     | Date picker, grouped matches, all tournament dates                                                              |
| M13 | TeamColors SRB Fix          | ✅ Done | TBD     | Removed duplicate "SRB" entry in TeamColors                                                                     |
| M14 | README.md                   | ✅ Done | TBD     | Industry-standard README with install + architecture                                                            |
| M15 | Auto-Update via Sparkle     | ✅ Done | TBD     | SPM integration, "Check for Updates" in Settings                                                                |
| M16 | GitHub Actions CI/CD        | ✅ Done | —       | ci.yml + release.yml, build/sign/notarize/release on tag push                                                   |
| M17 | Version Management Script   | ✅ Done | —       | bump-version.sh, semver validation, commit + tag                                                                |
| M18 | Test Suite                  | ✅ Done | —       | XCTest: Match, MatchStatus, Team, Standing, FetchService, MatchStore                                            |
| M19 | Full UI/UX Redesign         | ✅ Done | —       | Glass material, 520px panel, day pills, 12-team grid, live experience, hidden scrollbars, ±7 day schedule fetch |

## Key Decisions Log

| Date       | Decision                                                    | Rationale                                                                                                                            |
| ---------- | ----------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------ | --- | ---------- | ---------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------ |
| 2026-06-15 | football-data.org as primary API                            | Free, reliable, live scores, WC support                                                                                              |
| 2026-06-15 | Zero third-party dependencies                               | Tiny footprint, URLSession sufficient                                                                                                |
| 2026-06-15 | 60s poll interval (configurable, min 60s)                   | Balance between freshness and API limits                                                                                             |
| 2026-06-15 | Midnight auto-check when idle                               | No polling waste when no matches                                                                                                     |
| 2026-06-15 | Dynamic team colors                                         | Cool, contextual theming                                                                                                             |
| 2026-06-15 | Simple goal animation first                                 | Don't overcomplicate v1                                                                                                              |
| 2026-06-15 | @MainActor for MatchStore + PollController                  | Clean Swift 6 concurrency, no cross-iso                                                                                              |
| 2026-06-15 | Standing model → GroupStanding + StandingEntry              | Match football-data.org's table structure                                                                                            |
| 2026-06-15 | API key user-configurable in Settings                       | Normal users shouldn't edit source code                                                                                              |
| 2026-06-15 | API key stored in UserDefaults (@AppStorage)                | Matches existing pattern, good enough v1                                                                                             |
| 2026-06-15 | "No API key" error in header only                           | Non-blocking onboarding, user finds Settings themselves                                                                              |
| 2026-06-15 | Full Schedule tab with date picker                          | Spec required it, user chose to add now                                                                                              |
| 2026-06-15 | FetchService.apiKey made mutable                            | Allows runtime key updates from Settings                                                                                             |
| 2026-06-15 | Sparkle for auto-updates (not custom)                       | Industry standard, handles version check + download + verify + replace                                                               |
| 2026-06-15 | GitHub Releases as update feed                              | Free hosting, native GitHub API, no custom server needed                                                                             |
| 2026-06-15 | Tag-driven CI/CD pipeline                                   | Automated build → sign → notarize → publish on tag push                                                                              |
| 2026-06-15 | Version consistency: tag = MARKETING_VERSION                | Prevents false "update available" after installing latest                                                                            |
| 2026-06-15 | PollInterval uses backing store, not didSet                 | @Observable + didSet self-assignment causes infinite recursion (crash)                                                               |
| 2026-06-15 | Task wrapping for actor-isolated calls in didSet            | didSet is synchronous; actor calls need Task { await ... }                                                                           |
| 2026-06-15 | Environment injected inside MenuBarExtra label              | .environment() on Scene is invalid; apply to View children only                                                                      |
| 2026-06-15 | PRODUCT_MODULE_NAME set explicitly                          | PRODUCT_NAME "FIFAWC Scores" creates module "FIFAWC_Scores"; tests import "FIFAWCSCORES"                                             |
| 2026-06-15 | App renamed from WC Scores → FIFAWC Scores                  | Full rename across project, source, tests, CI/CD, docs, README. Bundle: com.fifawcscores.app                                         |     | 2026-06-15 | Tab row scroll hint gradient                   | Trailing LinearGradient when tabs overflow 340px panel — hints at scrollability                                                      |
| 2026-06-15 | Settings button added to footer (above Sync)                | Always-reachable shortcut to ⚙️ Settings tab, even when tab row is scrolled                                                          |
| 2026-06-15 | Auto-show Settings tab on first launch                      | When no API key is set, panel opens on ⚙️ Settings so user can paste key immediately                                                 |
| 2026-06-15 | Sparkle startingUpdater = false                             | Suppresses EdDSA + appcast 404 warnings in console; manual check via "Check for Updates…"                                            |
| 2026-06-15 | GitHub Pages site (docs/index.html)                         | Landing page inspired by prayer-times-macos; emoji-based, no screenshots yet, SEO structured                                         |
| 2026-06-16 | Full UI/UX redesign (M19)                                   | Glass material, 520px panel, day pills, 12-team grid, live experience, hidden scrollbars                                             |
| 2026-06-16 | Panel height fixed at 520px                                 | Consistent size like prayer app; content scrolls inside                                                                              |
| 2026-06-16 | Glass material: .ultraThinMaterial + .regularMaterial cards | Native macOS frosted glass look, modern and clean                                                                                    |
| 2026-06-16 | Horizontal day pills replacing DatePicker                   | 15-day scrollable row of date capsules; more visual, modern feel                                                                     |
| 2026-06-16 | MatchStore.fetchScheduleAround(\_:) for ±7 days             | Schedule tab fetches ±7 days around picker date; fixes empty schedule bug                                                            |
| 2026-06-16 | 12 popular teams + TLA search for favorites                 | Expanded from 6 hardcoded to 12 + search field; all 48 nations searchable                                                            |
| 2026-06-16 | Unified Settings fonts (.caption.weight(.medium))           | Consistent typography across all Settings sections                                                                                   |
| 2026-06-16 | Hidden scrollbars (.scrollIndicators(.hidden))              | Cleaner look; content scrolls naturally without visible scroll chrome                                                                |
| 2026-06-16 | Pulsing red dot for live matches                            | 1s ease-in-out repeat animation on header + MatchCard live indicator                                                                 |
| 2026-06-16 | TeamColors on live match cards                              | Home/away team TLA shown in team color; card border tinted with home team color                                                      |
| 2026-06-16 | Removed black LinearGradient scroll hint                    | Was unprofessional; replaced with natural scroll + hidden indicators                                                                 |
| 2026-06-16 | MenuBarLabel "FWC" text verified correct                    | Shows "FWC" only when no featuredMatch; shows match data once API loads                                                              |
| 2026-06-16 | PollController idle state polls every 120s                  | Was sleeping until midnight → missed TIMED→IN_PLAY transitions. Now catches them in ≤2 min                                           |
| 2026-06-16 | FetchService uses dedicated URLSession (no cache)           | URLSession.shared cached stale TIMED responses on disk; .reloadIgnoringLocalCacheData + no urlCache + Cache-Control: no-cache header |
| 2026-06-16 | MatchStatus: added EXTRA_TIME + PENALTY_SHOOTOUT            | API returns these for extra time/penalties; missing cases caused JSON decode failures                                                |
| 2026-06-16 | Response-header rate limiting (X-RequestsAvailable)         | API email warned about throttling; now reads X-RequestsAvailable + X-RequestCounter-Reset headers                                    |
| 2026-06-16 | Client-side status inference (`effectiveStatus`)            | football-data.org free tier returns stale TIMED status even when match is LIVE; clock-based inference overrides stale API data       |
| 2026-06-16 | Reverted: removed clock tick, restored stable menu bar      | Multiple wobble fix attempts (Prompts 24–27) each introduced new problems. Reverted to stable state at d82dc21 for panel stability.  |     | 2026-06-16 | Timezone fix: dateString() uses local timezone | UTC grouping caused matches to appear in wrong tabs (CIV vs ECU in Yesterday instead of Today). Now matches Google's local grouping. |
| 2026-06-16 | Menu bar: plain system default color (like prayer app)      | Removed labelColor, GoalAnimationView, .contentTransition, .animation. Just ⚽ + text, zero modifiers.                               |
| 2026-06-16 | Panel height: maxHeight + layoutPriority(-1) on content    | Panel shrinks to content when short (footer pulls up), caps at 520px when content exceeds. Schedule tab timezone also fixed.          |
| 2026-06-16 | Panel polish: scroll, scrollbar, settings, hover, Sparkle   | Threshold >4, .scrollIndicatorsVisibility(.hidden), Settings in ScrollView, rounded hover, version badge replaces Check for Updates      |

## Architecture Quick Reference

- **App**: SwiftUI `MenuBarExtra` (.window style), macOS 14+
- **State**: `@Observable @MainActor` MatchStore drives all views
- **API**: football-data.org v4, URLSession, X-Auth-Token header
- **API Key**: User-configurable in Settings tab, stored in UserDefaults
- **Polling**: Task-based state machine (idle ↔ live), 120s idle polling, no-cache URLSession
- **Status Inference**: `Match.effectiveStatus` overrides stale API status using match clock logic (0–135 min after kickoff → IN_PLAY)
- **Panel Height**: 520px max, shrinks to content when fewer matches (footer pulls up). `.layoutPriority(-1)` on content. Scroll threshold: >4 matches.
- **Scrollbar**: `.scrollIndicatorsVisibility(.hidden)` on ALL ScrollViews (force-hidden, ignores system preference).
- **Settings**: Wrapped in ScrollView (too tall for single view).
- **Hover**: Rounded corners (cornerRadius: 6) on footer/button highlights.
- **Sparkle**: Auto-checks on launch (`startingUpdater: true`). Version badge replaces Check for Updates button.
- **Rate Limiting**: Response-header-aware (X-RequestsAvailable, X-RequestCounter-Reset) + local sliding window
- **Build**: XcodeGen (`project.yml`), Swift 6, strict concurrency

## File Structure

```
Sources/
  App/
    FIFAWCScoresApp.swift          # @main entry, creates MatchStore, injects via .environment
  Models/
    Match.swift                # Match, Score, ScoreValues
    MatchStatus.swift          # Enum: scheduled/timed/in_play/paused/finished/...
    Team.swift                 # Team struct + TeamFlags emoji dictionary
    Standing.swift             # StandingEntry + GroupStanding (matches API structure)
    TeamColors.swift           # Hardcoded team color dictionary (30+ nations)
  Services/
    FetchService.swift         # actor FetchService — football-data.org API client
    MatchStore.swift           # @Observable @MainActor — central state, goal detection
    PollController.swift       # @MainActor class — polling state machine
  Views/
    MenuBarLabel.swift         # Compact menu bar (3 states + goal animation)
    MenuBarPanel.swift         # Expanded panel (6 tabs: Today/Yesterday/Tomorrow/Schedule/Standings/Settings)
  Resources/
    Info.plist                 # LSUIElement = true (no Dock icon)
    Assets.xcassets/           # AccentColor (FIFA purple), AppIcon (placeholder)
```

## Remaining Before Distribution

4. ~~**App Icon**: Create actual AppIcon assets (256x256, 128x128, etc.)~~
5. **Xcode Build**: Full build with Xcode (not just `swiftc -parse`) to catch runtime issues
6. **Real-world testing**: Test with live tournament data when WC 2026 starts
7. ~~**Code signing**: Developer ID + notarization for distribution~~
8. ~~**Sparkle integration**: Add auto-update framework (M15)~~ ✅ Done
9. ~~**GitHub Actions**: CI/CD pipeline for automated builds (M16)~~ ✅ Done
10. ~~**Version management**: Script to bump version + create tags (M17)~~ ✅ Done
11. ~~**Test suite**: Unit tests for core logic (M18)~~ ✅ Done
12. **Ed25519 keys**: Generate Sparkle signing keys (before first signed release)

## Agent Instructions

When working on this project:

1. Read this file first to know the current stage
2. Check `docs/spec.md` for the full implementation contract
3. Check `docs/plan.md` for the milestone details
4. Update this file when you complete a milestone or make a key decision
5. Follow conventions in CLAUDE.md
