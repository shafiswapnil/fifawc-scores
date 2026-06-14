# Project Status — WC Scores

> This file tracks the current stage of the project for any agent or LLM
> working on it. Always update this file when milestones are completed.

## Current Stage

**Phase 1 complete (M1–M14).** App features done. Phase 2 planned: auto-update via Sparkle + GitHub Actions CI/CD pipeline.

## Milestone Tracker

| #   | Milestone                   | Status  | Commit  | Notes                                                  |
| --- | --------------------------- | ------- | ------- | ------------------------------------------------------ |
| M1  | Project Scaffolding         | ✅ Done | 157f5f3 | XcodeGen, dirs, Info.plist, empty MenuBarExtra         |
| M2  | Data Models                 | ✅ Done | bced77f | Match, Team, Standing, MatchStatus, TeamColors         |
| M3  | API Client (FetchService)   | ✅ Done | 88a5c5a | football-data.org v4, URLSession, rate limiter         |
| M4  | MatchStore (Central State)  | ✅ Done | 102e099 | @Observable @MainActor, goal detection, computed props |
| M5  | PollController (Scheduling) | ✅ Done | 102e099 | State machine: idle→live→idle, midnight rollover       |
| M6  | MenuBarLabel                | ✅ Done | 9a90463 | 3 states: idle/upcoming/live, dynamic team colors      |
| M7  | Goal Animation              | ✅ Done | 9a90463 | ⚨ slide left→right (1.5s ease-in-out)                  |
| M8  | MenuBarPanel                | ✅ Done | b310017 | Tabs, MatchCards, GroupStandingCards, footer           |
| M9  | Settings (In-Panel)         | ✅ Done | 2a19c7b | Poll interval slider, favorite team picker             |
| M10 | Polish & Testing            | ✅ Done | 0d5b386 | Cleaned duplicate TLA keys, all files compile clean    |
| M11 | API Key in Settings         | ✅ Done | TBD     | UserDefaults storage, Settings UI, error in header     |
| M12 | Full Schedule Tab           | ✅ Done | TBD     | Date picker, grouped matches, all tournament dates     |
| M13 | TeamColors SRB Fix          | ✅ Done | TBD     | Removed duplicate "SRB" entry in TeamColors            |
| M14 | README.md                   | ✅ Done | TBD     | Industry-standard README with install + architecture   |
| M15 | Auto-Update via Sparkle      | ⬜ Plan | —       | SPM integration, "Check for Updates" in Settings       |
| M16 | GitHub Actions CI/CD        | ⬜ Plan | —       | Build, sign, notarize, publish on tag push             |
| M17 | Version Management Script   | ⬜ Plan | —       | bump-version.sh, semver, tag ↔ project.yml sync       |
| M18 | Test Suite                  | ⬜ Plan | —       | XCTest for FetchService, MatchStore, models            |

## Git History

```
6efbe7c (HEAD) feat: add API key in Settings, Full Schedule tab, fix TeamColors, README
0d5b386 chore: clean up Team.swift duplicate TLA keys (M10)
2a19c7b feat(settings): add in-panel settings tab (M9)
b310017 feat(ui): add MenuBarPanel with tabs, match cards, standings (M8)
9a90463 feat(ui): add MenuBarLabel with real data + goal animation (M6+M7)
102e099 feat(state): add MatchStore + PollController (M4+M5)
88a5c5a feat(api): add FetchService for football-data.org (M3)
bced77f feat(models): add core data models (M2)
157f5f3 chore: initial project scaffolding (M1)
```

## Key Decisions Log

| Date       | Decision                                       | Rationale                                               |
| ---------- | ---------------------------------------------- | ------------------------------------------------------- |
| 2026-06-15 | football-data.org as primary API               | Free, reliable, live scores, WC support                 |
| 2026-06-15 | Zero third-party dependencies                  | Tiny footprint, URLSession sufficient                   |
| 2026-06-15 | 60s poll interval (configurable, min 60s)      | Balance between freshness and API limits                |
| 2026-06-15 | Midnight auto-check when idle                  | No polling waste when no matches                        |
| 2026-06-15 | Dynamic team colors                            | Cool, contextual theming                                |
| 2026-06-15 | Simple goal animation first                    | Don't overcomplicate v1                                 |
| 2026-06-15 | @MainActor for MatchStore + PollController     | Clean Swift 6 concurrency, no cross-iso                 |
| 2026-06-15 | Standing model → GroupStanding + StandingEntry | Match football-data.org's table structure               |
| 2026-06-15 | API key user-configurable in Settings          | Normal users shouldn't edit source code                 |
| 2026-06-15 | API key stored in UserDefaults (@AppStorage)   | Matches existing pattern, good enough v1                |
| 2026-06-15 | "No API key" error in header only              | Non-blocking onboarding, user finds Settings themselves |
| 2026-06-15 | Full Schedule tab with date picker             | Spec required it, user chose to add now                 |
| 2026-06-15 | FetchService.apiKey made mutable               | Allows runtime key updates from Settings                |
| 2026-06-15 | Sparkle for auto-updates (not custom)           | Industry standard, handles version check + download + verify + replace |
| 2026-06-15 | GitHub Releases as update feed                  | Free hosting, native GitHub API, no custom server needed |
| 2026-06-15 | Tag-driven CI/CD pipeline                       | Automated build → sign → notarize → publish on tag push |
| 2026-06-15 | Version consistency: tag = MARKETING_VERSION    | Prevents false "update available" after installing latest |

## Architecture Quick Reference

- **App**: SwiftUI `MenuBarExtra` (.window style), macOS 14+
- **State**: `@Observable @MainActor` MatchStore drives all views
- **API**: football-data.org v4, URLSession, X-Auth-Token header
- **API Key**: User-configurable in Settings tab, stored in UserDefaults
- **Polling**: Task-based state machine (idle ↔ live), midnight UTC rollover
- **Build**: XcodeGen (`project.yml`), Swift 6, strict concurrency

## File Structure

```
Sources/
  App/
    WCScoresApp.swift          # @main entry, creates MatchStore, injects via .environment
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

1. ~~**API Key**: User enters their own key in Settings~~ ✅ Done
2. **App Icon**: Create actual AppIcon assets (256x256, 128x128, etc.)
3. **Xcode Build**: Full build with Xcode (not just `swiftc -parse`) to catch runtime issues
4. **Real-world testing**: Test with live tournament data when WC 2026 starts
5. **Code signing**: Developer ID + notarization for distribution
6. **Sparkle integration**: Add auto-update framework (M15)
7. **GitHub Actions**: CI/CD pipeline for automated builds (M16)
8. **Version management**: Script to bump version + create tags (M17)
9. **Test suite**: Unit tests for core logic (M18)

## Agent Instructions

When working on this project:

1. Read this file first to know the current stage
2. Check `docs/spec.md` for the full implementation contract
3. Check `docs/plan.md` for the milestone details
4. Update this file when you complete a milestone or make a key decision
5. Follow conventions in CLAUDE.md
