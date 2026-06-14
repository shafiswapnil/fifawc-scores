# Project Status — FIFAWC Scores

> This file tracks the current stage of the project for any agent or LLM
> working on it. Always update this file when milestones are completed.

## Current Stage

**Phase 1 complete (M1–M14). Phase 2 complete (M15–M18).** App features done. Auto-update via Sparkle, CI/CD pipeline, version management, and test suite all implemented.

## Milestone Tracker

| #   | Milestone                   | Status  | Commit  | Notes                                                                |
| --- | --------------------------- | ------- | ------- | -------------------------------------------------------------------- |
| M1  | Project Scaffolding         | ✅ Done | 157f5f3 | XcodeGen, dirs, Info.plist, empty MenuBarExtra                       |
| M2  | Data Models                 | ✅ Done | bced77f | Match, Team, Standing, MatchStatus, TeamColors                       |
| M3  | API Client (FetchService)   | ✅ Done | 88a5c5a | football-data.org v4, URLSession, rate limiter                       |
| M4  | MatchStore (Central State)  | ✅ Done | 102e099 | @Observable @MainActor, goal detection, computed props               |
| M5  | PollController (Scheduling) | ✅ Done | 102e099 | State machine: idle→live→idle, midnight rollover                     |
| M6  | MenuBarLabel                | ✅ Done | 9a90463 | 3 states: idle/upcoming/live, dynamic team colors                    |
| M7  | Goal Animation              | ✅ Done | 9a90463 | ⚨ slide left→right (1.5s ease-in-out)                                |
| M8  | MenuBarPanel                | ✅ Done | b310017 | Tabs, MatchCards, GroupStandingCards, footer                         |
| M9  | Settings (In-Panel)         | ✅ Done | 2a19c7b | Poll interval slider, favorite team picker                           |
| M10 | Polish & Testing            | ✅ Done | 0d5b386 | Cleaned duplicate TLA keys, all files compile clean                  |
| M11 | API Key in Settings         | ✅ Done | TBD     | UserDefaults storage, Settings UI, error in header                   |
| M12 | Full Schedule Tab           | ✅ Done | TBD     | Date picker, grouped matches, all tournament dates                   |
| M13 | TeamColors SRB Fix          | ✅ Done | TBD     | Removed duplicate "SRB" entry in TeamColors                          |
| M14 | README.md                   | ✅ Done | TBD     | Industry-standard README with install + architecture                 |
| M15 | Auto-Update via Sparkle     | ✅ Done | TBD     | SPM integration, "Check for Updates" in Settings                     |
| M16 | GitHub Actions CI/CD        | ✅ Done | —       | ci.yml + release.yml, build/sign/notarize/release on tag push        |
| M17 | Version Management Script   | ✅ Done | —       | bump-version.sh, semver validation, commit + tag                     |
| M18 | Test Suite                  | ✅ Done | —       | XCTest: Match, MatchStatus, Team, Standing, FetchService, MatchStore |

## Key Decisions Log

| Date       | Decision                                         | Rationale                                                                                    |
| ---------- | ------------------------------------------------ | -------------------------------------------------------------------------------------------- |
| 2026-06-15 | football-data.org as primary API                 | Free, reliable, live scores, WC support                                                      |
| 2026-06-15 | Zero third-party dependencies                    | Tiny footprint, URLSession sufficient                                                        |
| 2026-06-15 | 60s poll interval (configurable, min 60s)        | Balance between freshness and API limits                                                     |
| 2026-06-15 | Midnight auto-check when idle                    | No polling waste when no matches                                                             |
| 2026-06-15 | Dynamic team colors                              | Cool, contextual theming                                                                     |
| 2026-06-15 | Simple goal animation first                      | Don't overcomplicate v1                                                                      |
| 2026-06-15 | @MainActor for MatchStore + PollController       | Clean Swift 6 concurrency, no cross-iso                                                      |
| 2026-06-15 | Standing model → GroupStanding + StandingEntry   | Match football-data.org's table structure                                                    |
| 2026-06-15 | API key user-configurable in Settings            | Normal users shouldn't edit source code                                                      |
| 2026-06-15 | API key stored in UserDefaults (@AppStorage)     | Matches existing pattern, good enough v1                                                     |
| 2026-06-15 | "No API key" error in header only                | Non-blocking onboarding, user finds Settings themselves                                      |
| 2026-06-15 | Full Schedule tab with date picker               | Spec required it, user chose to add now                                                      |
| 2026-06-15 | FetchService.apiKey made mutable                 | Allows runtime key updates from Settings                                                     |
| 2026-06-15 | Sparkle for auto-updates (not custom)            | Industry standard, handles version check + download + verify + replace                       |
| 2026-06-15 | GitHub Releases as update feed                   | Free hosting, native GitHub API, no custom server needed                                     |
| 2026-06-15 | Tag-driven CI/CD pipeline                        | Automated build → sign → notarize → publish on tag push                                      |
| 2026-06-15 | Version consistency: tag = MARKETING_VERSION     | Prevents false "update available" after installing latest                                    |
| 2026-06-15 | PollInterval uses backing store, not didSet      | @Observable + didSet self-assignment causes infinite recursion (crash)                       |
| 2026-06-15 | Task wrapping for actor-isolated calls in didSet | didSet is synchronous; actor calls need Task { await ... }                                   |
| 2026-06-15 | Environment injected inside MenuBarExtra label   | .environment() on Scene is invalid; apply to View children only                              |
| 2026-06-15 | PRODUCT_MODULE_NAME set explicitly               | PRODUCT_NAME "FIFAWC Scores" creates module "FIFAWC_Scores"; tests import "FIFAWCSCORES"     |
| 2026-06-15 | App renamed from WC Scores → FIFAWC Scores       | Full rename across project, source, tests, CI/CD, docs, README. Bundle: com.fifawcscores.app |

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
