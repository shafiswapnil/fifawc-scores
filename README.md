<div align="center">

# ⚽ WC Scores

**Native macOS menu bar app for FIFA World Cup 2026**

Live scores, match schedules, and goal animations — right from your menu bar.

No Dock icon. No bloat. Just football.

[![macOS 14+](https://img.shields.io/badge/macOS-14%2B-blue)](https://developer.apple.com/macos/)
[![Swift 6](https://img.shields.io/badge/Swift-6-orange)](https://www.swift.org)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

</div>

---

## Features

- **Menu bar agent** — lives in the menu bar, no Dock icon clutter
- **Live scores** — real-time updates with configurable polling (60–300s)
- **Goal animations** — ⚨ slides across the menu bar when a goal is scored
- **Match schedule** — Today, Yesterday, Tomorrow, and Full Tournament tabs
- **Standings** — Group-stage tables (A–H) with points, goal difference, form
- **Favorite team** — prioritize your team in the menu bar display
- **Zero dependencies** — pure SwiftUI + URLSession, no third-party packages
- **Lightweight** — tiny RAM/CPU footprint, native macOS feel

## Screenshots

> _Coming soon — menu bar label, panel with tabs, goal animation_

## Requirements

- **macOS 14.0+** (Sonoma or later)
- **Xcode 16+** with Swift 6 support
- **[football-data.org](https://www.football-data.org) API key** (free tier: 10 requests/min)

## Getting an API Key

1. Go to [football-data.org/client/register](https://www.football-data.org/client/register)
2. Create a free account
3. Copy your API key from the dashboard
4. Open WC Scores → Settings tab → paste your key

> The free tier allows 10 requests per minute — more than enough for this app.

## Install (Build from Source)

```bash
# 1. Clone the repository
git clone https://github.com/yourusername/fifawc-scores.git
cd fifawc-scores

# 2. Install XcodeGen (if not installed)
brew install xcodegen

# 3. Generate the Xcode project
xcodegen generate

# 4. Open in Xcode
open WCSCORES.xcodeproj
```

Then press **⌘R** to build and run. The app will appear in your menu bar.

### Build via command line

```bash
xcodegen generate
xcodebuild -project WCSCORES.xcodeproj -scheme WCSCORES \
  -configuration Debug -destination 'platform=macOS' \
  CODE_SIGNING_ALLOWED=NO build
```

## Usage

1. **Launch** — double-click WC Scores (or ⌘R in Xcode)
2. **Set API key** — click the ⚙️ tab, paste your key
3. **Watch** — matches auto-poll, live scores update in the menu bar

### Menu Bar Display

| State    | Example                          |
| -------- | -------------------------------- |
| Idle     | `⚽ WC`                          |
| Upcoming | `⚽ BRA vs ARG · 3:00 PM`        |
| Live     | `⚽ BRA 2 - 1 ARG · 67'`         |
| Goal     | `⚽ BRA 2 - 1 ARG` + ⚨ animation |

### Panel Tabs

| Tab             | Description                               |
| --------------- | ----------------------------------------- |
| **Today**       | Today's matches, live first               |
| **Yesterday**   | Yesterday's results                       |
| **Tomorrow**    | Upcoming fixtures                         |
| **Schedule**    | Full tournament schedule with date picker |
| **Standings**   | Group tables (A–H)                        |
| **⚙️ Settings** | API key, poll interval, favorite team     |

## Architecture

```
Sources/
├── App/
│   └── WCScoresApp.swift        # @main entry, app lifecycle
├── Models/
│   ├── Match.swift               # Match data model
│   ├── MatchStatus.swift         # Status enum (scheduled, live, finished…)
│   ├── Standing.swift            # Group standings model
│   ├── Team.swift                # Team + flag emoji mapping
│   └── TeamColors.swift          # Team color theming
├── Services/
│   ├── FetchService.swift        # football-data.org API client (actor)
│   ├── MatchStore.swift          # Central @Observable state
│   └── PollController.swift      # Polling loop with smart intervals
├── Views/
│   ├── MenuBarLabel.swift        # Menu bar icon/text + goal animation
│   └── MenuBarPanel.swift        # Tabbed panel with match cards
└── Resources/
    └── Info.plist                # LSUIElement = true (no Dock icon)
```

### Key Design Decisions

- **`@Observable`** for state management (no Combine)
- **`@MainActor`** isolation for MatchStore and PollController (clean concurrency)
- **`actor`** for FetchService (network state isolation)
- **Swift 6 strict concurrency** (`SWIFT_STRICT_CONCURRENCY=complete`)
- **XcodeGen** for project generation (`project.yml`)

## Settings

| Setting       | Default | Description                              |
| ------------- | ------- | ---------------------------------------- |
| API Key       | (empty) | Your football-data.org API key           |
| Poll Interval | 60s     | How often to fetch live scores (60–300s) |
| Favorite Team | None    | Prioritized in menu bar display          |

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

## License

MIT — use it, fork it, improve it.

---

<div align="center">

**Built with ❤️ for the beautiful game**

</div>
