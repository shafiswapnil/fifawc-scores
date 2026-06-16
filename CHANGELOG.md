# Changelog — FIFAWC Scores

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [1.0.0] — 2026-06-16

First public release.

### Added
- **Dynamic menu bar label** — 5 states: Idle, Upcoming, Live (with minute counter), Half-time, Finished
- **6 tabbed views** — Today, Yesterday, Tomorrow, Full Schedule, Standings, Settings
- **GOAL! alert** — menu bar label flashes "GOAL!" for 5 seconds when a goal is scored
- **Favorite team pinning** — pin your team to top of Today tab with orange glow highlight + Schedule tab filtering
- **Dynamic team colors** — match cards tinted with team colors for all 48 World Cup nations
- **Dark glass panels** — TRIONDA brand: vibrant orange (#F26622) accent, violet (#5B0A82), magenta (#C32B5A)
- **`DarkModeBridge`** — AppKit bridge that forces dark mode in MenuBarExtra (SwiftUI limitation workaround)
- **Smart polling** — configurable 60–300s interval with live/idle state machine to minimize API usage
- **Auto-update via Sparkle** — checks GitHub Releases for new versions
- **Settings in-panel** — API key input, poll interval slider, favorite team picker with 12 popular nations + search
- **3D soccer ball SF Symbol** icon in menu bar
- **GitHub Actions CI/CD** — `ci.yml` for PR checks, `release.yml` for tag-triggered build → sign → notarize → release
- **54 unit tests** covering models, services, store, and fetch logic

### Tech Stack
- Swift 6 with strict concurrency
- SwiftUI with `@Observable` (no Combine)
- macOS 14+ deployment target, universal binary (Apple Silicon + Intel)
- XcodeGen for project generation
- Sparkle (SPM) for auto-updates
- football-data.org API v4 for live scores

[1.0.0]: https://github.com/shafiswapnil/fifawc-scores/releases/tag/v1.0.0
