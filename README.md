<div align="center">
  <h1>⚽ FIFAWC Scores</h1>
  <p><strong>Native macOS menu bar app for FIFA World Cup 2026</strong></p>
  <p>Live scores, match schedules, goal animations, and auto-updates — right from your menu bar.</p>

  <p>
    <a href="https://github.com/shafiswapnil/fifawc-scores/releases/latest"><img src="https://img.shields.io/github/v/release/shafiswapnil/fifawc-scores?label=download&color=2e9e4c" alt="Latest release"></a>
    <a href="https://github.com/shafiswapnil/fifawc-scores/releases"><img src="https://img.shields.io/github/downloads/shafiswapnil/fifawc-scores/total?color=2e9e4c" alt="Total downloads"></a>
    <img src="https://img.shields.io/badge/macOS-14%2B-blue" alt="macOS 14+">
    <img src="https://img.shields.io/badge/Swift-6-orange" alt="Swift 6">
    <img src="https://img.shields.io/badge/Apple%20silicon%20%2B%20Intel-Universal-lightgrey" alt="Universal binary">
    <a href="LICENSE"><img src="https://img.shields.io/github/license/shafiswapnil/fifawc-scores?color=blue" alt="MIT license"></a>
  </p>
</div>

---

**FIFAWC Scores** is a lightweight, open-source **macOS menu bar agent** that shows
FIFA World Cup 2026 match schedules, live scores, and goal animations — all from
the menu bar. No Dock icon, no main window, no bloat. It fetches live data from
[football-data.org](https://www.football-data.org) and auto-updates via
[Sparkle](https://github.com/sparkle-project/Sparkle) when you install new
releases from GitHub.

## Install

**Download** — grab the latest `.zip` from
[Releases](https://github.com/shafiswapnil/fifawc-scores/releases/latest), unzip,
and drag **FIFAWC Scores.app** to your Applications folder.

> **First launch (unsigned build):** macOS may block the app because it's not
> notarized yet. Go to **System Settings → Privacy & Security** and click **Open
> Anyway**, then **Open** in the confirmation dialog. (Or run `xattr -dr
com.apple.quarantine "/Applications/FIFAWC Scores.app"` in Terminal.)

**Auto-updates:** once installed, the app checks for new releases automatically.
Click **Settings → Check for Updates…** to manually check. Sparkle handles
download, verification, and restart.

Requirements: **macOS 14 Sonoma or later** · Universal (Apple Silicon + Intel).

## Features

- **Menu bar at a glance** — live scores, upcoming matches, goal animations
- **6 tabbed views** — Today, Yesterday, Tomorrow, Full Schedule, Standings, Settings
- **Goal animation** — ⚨ slides across the menu bar when a goal is scored
- **Dynamic team colors** — menu bar accent adapts to the featured match
- **Favorite team** — prioritize your team in the menu bar display
- **Live polling** — configurable interval (60–300s), smart idle/live state machine
- **Auto-update** — Sparkle framework checks GitHub Releases for new versions
- **Lightweight** — tiny RAM/CPU footprint, native SwiftUI, no Electron
- **One dependency** — [Sparkle](https://github.com/sparkle-project/Sparkle) (~2MB), everything else is native

## Getting an API Key

1. Go to [football-data.org/client/register](https://www.football-data.org/client/register)
2. Create a free account
3. Copy your API key from the dashboard
4. Open FIFAWC Scores → ⚙️ Settings tab → paste your key

> The free tier allows 10 requests per minute — more than enough for this app.

## Install (Build from Source)

```bash
# 1. Clone the repository
git clone https://github.com/shafiswapnil/fifawc-scores.git
cd fifawc-scores

# 2. Install XcodeGen (if not installed)
brew install xcodegen

# 3. Generate the Xcode project
xcodegen generate

# 4. Open in Xcode
open FIFAWCSCORES.xcodeproj
```

Then press **⌘R** to build and run. The app will appear in your menu bar.

### Build via command line

```bash
xcodegen generate
xcodebuild -project FIFAWCSCORES.xcodeproj -scheme FIFAWCSCORES \
  -configuration Debug -destination 'platform=macOS' \
  CODE_SIGNING_ALLOWED=NO build
```

## Usage

1. **Launch** — double-click FIFAWC Scores (or ⌘R in Xcode)
2. **Set API key** — click the ⚙️ tab, paste your key
3. **Watch** — matches auto-poll, live scores update in the menu bar

### Menu Bar Display

| State    | Example                          |
| -------- | -------------------------------- |
| Idle     | `⚽ FWC`                         |
| Upcoming | `⚽ BRA vs ARG · 3:00 PM`        |
| Live     | `⚽ BRA 2 - 1 ARG · 67'`         |
| Goal     | `⚽ BRA 2 - 1 ARG` + ⚨ animation |

### Panel Tabs

| Tab             | Description                                              |
| --------------- | -------------------------------------------------------- |
| **Today**       | Today's matches, live first                              |
| **Yesterday**   | Yesterday's results                                      |
| **Tomorrow**    | Upcoming fixtures                                        |
| **Schedule**    | Full tournament schedule with date picker                |
| **Standings**   | Group tables (A–H)                                       |
| **⚙️ Settings** | API key, poll interval, favorite team, check for updates |

## Architecture

```
Sources/
├── App/
│   └── FIFAWCScoresApp.swift        # @main entry, Sparkle auto-updater
├── Models/
│   ├── Match.swift               # Match data model + Codable
│   ├── MatchStatus.swift         # Status enum (scheduled, live, finished…)
│   ├── Standing.swift            # Group standings model
│   ├── Team.swift                # Team + flag emoji mapping (48 nations)
│   └── TeamColors.swift          # Team color theming
├── Services/
│   ├── FetchService.swift        # football-data.org API client (actor)
│   ├── MatchStore.swift          # Central @Observable state
│   └── PollController.swift      # Polling loop with smart intervals
├── Views/
│   ├── MenuBarLabel.swift        # Menu bar icon/text + goal animation
│   └── MenuBarPanel.swift        # Tabbed panel with match cards + settings
└── Resources/
    └── Info.plist                # LSUIElement, SUFeedURL (Sparkle)
Tests/
└── WCScoreTests/                 # XCTest suite
    ├── MatchTests.swift
    ├── MatchStatusTests.swift
    ├── TeamTests.swift
    ├── StandingTests.swift
    ├── FetchServiceTests.swift
    └── MatchStoreTests.swift
scripts/
└── bump-version.sh               # Version management (semver, commit, tag)
.github/workflows/
├── ci.yml                        # PR/push checks (parse + build + tests)
└── release.yml                   # Tag-triggered build → sign → release
```

### Key Design Decisions

- **`@Observable`** for state management (no Combine)
- **`@MainActor`** isolation for MatchStore and PollController
- **`actor`** for FetchService (network state isolation)
- **Swift 6 strict concurrency** (`SWIFT_STRICT_CONCURRENCY=complete`)
- **XcodeGen** for project generation (`project.yml` → `.xcodeproj`)
- **Sparkle** for auto-updates (GitHub Releases as feed)

## Settings

| Setting           | Default | Description                              |
| ----------------- | ------- | ---------------------------------------- |
| API Key           | (empty) | Your football-data.org API key           |
| Poll Interval     | 60s     | How often to fetch live scores (60–300s) |
| Favorite Team     | None    | Prioritized in menu bar display          |
| Check for Updates | —       | Manually check GitHub for new releases   |

## API

This app uses the [football-data.org](https://www.football-data.org/docs/v4/) API v4.

- **Competition code**: `WC` (FIFA World Cup)
- **Auth**: `X-Auth-Token` header
- **Rate limit**: 10 requests/min (free tier)
- **Data**: Match schedules, live scores, group standings

## Tech Stack

| Component   | Technology                                 |
| ----------- | ------------------------------------------ |
| UI          | SwiftUI (MenuBarExtra + MenuBarLabelStyle) |
| Networking  | URLSession                                 |
| State       | @Observable + @MainActor                   |
| Concurrency | Swift 6 strict concurrency                 |
| Project     | XcodeGen                                   |
| API         | football-data.org v4                       |
| Auto-update | Sparkle (GitHub Releases feed)             |
| CI/CD       | GitHub Actions (build, sign, notarize)     |

## Releasing

Releases are automated via GitHub Actions. When a version tag is pushed:

1. CI validates the version matches `project.yml`
2. Builds the `.app` bundle
3. Optionally signs + notarizes (when secrets are configured)
4. Creates a GitHub Release with the `.zip` attached
5. Updates `appcast.xml` for Sparkle auto-updates

```bash
# To make a release:
./scripts/bump-version.sh 1.1.0
git push origin main --tags
```

## License

[MIT](LICENSE)

---

<div align="center">

**Built with ❤️ for the beautiful game**

</div>
