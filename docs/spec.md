# FIFAWC Scores — macOS Menu Bar App

### Technical Specification (v1.0)

> A native, lightweight macOS menu bar application that displays FIFA World
> Cup 2026 match schedules, live scores, goal animations, and group standings —
> all within the menu bar area. No Dock icon, no main window, zero login items.

---

## 1. Overview

The app lives in the macOS menu bar as a lightweight agent. It shows today's
(or the next upcoming) match in the menu bar label with a countdown. During
live matches, it shows a real-time score that polls every minute. When a goal
is scored, a tiny football emoji animates across the menu bar text area.

Clicking the menu bar item opens a panel showing match schedules for
previous/today/tomorrow/the whole month, live scores, and group standings.

The user opens the app manually (no auto-start). Once open, it stays resident
in the menu bar until quit.

---

## 2. Goals & Non-Goals

### Goals

- Native macOS, SwiftUI-first, idiomatic and lightweight.
- Menu bar resident — glanceable match info without opening anything.
- Live score polling during matches (configurable interval, min 60s).
- Goal animation: tiny ⚽ slides left-to-right across menu bar text area.
- Panel with match schedules: previous day, today, tomorrow, whole month.
- Panel with group standings.
- Manual sync button in the panel.
- Dynamic team-color theming based on featured match.
- Zero login items, zero Dock icon.
- Minimal RAM/CPU — polling pauses when no live matches.

### Non-Goals (v1)

- Notifications / alerts before match starts (future).
- Favorite team filtering (future).
- Golden Boot / top scorer tracking (future).
- Knockout bracket view (future).
- Settings window (use panel for all settings in v1).
- iCloud sync or iOS companion.
- App Store distribution.

---

## 3. Technology Stack

| Concern      | Choice                                   | Rationale                                 |
| ------------ | ---------------------------------------- | ----------------------------------------- |
| Language     | **Swift 6** (strict concurrency)         | Native, modern, safe.                     |
| UI           | **SwiftUI** + minimal AppKit bridging    | `MenuBarExtra` is SwiftUI-native.         |
| Menu bar     | **`MenuBarExtra`** (`.window` style)     | Available macOS 13+; rich custom panel.   |
| Agent mode   | `LSUIElement = true`                     | No Dock icon, no main window.             |
| Networking   | **`URLSession`** (native)                | No third-party HTTP libs needed.          |
| Data API     | **football-data.org** v4                 | Free tier, 10 req/min, live match status. |
| Persistence  | **`UserDefaults`** via `@AppStorage`     | Small config surface; no database.        |
| Package mgmt | **XcodeGen** + **Swift Package Manager** | Clean project generation.                 |
| Architecture | **MVVM** with `@Observable`              | Modern SwiftUI state management.          |

### External dependencies

- **None** in v1. Pure native Swift + URLSession.

---

## 4. System Requirements

- **Minimum deployment target:** macOS 14 Sonoma.
- **Architecture:** Universal binary (Apple Silicon + Intel).
- **Signing:** Ad-hoc for local dev; Developer ID + notarization for distribution.

---

## 5. High-Level Architecture

```
┌──────────────────────────────────────────────────────────────┐
│  App layer  (SwiftUI)                                         │
│  • MenuBarExtra (label + panel)                               │
│  • @main App                                                  │
└───────────────┬───────────────────────────────────────────────┘
                │
      ┌─────────▼──────────────┐
      │   MatchStore           │  @Observable, drives everything
      │   • live state         │
      │   • schedule cache     │
      │   • poll controller    │
      └────┬──────────┬────────┘
           │          │
  ┌────────▼───┐  ┌───▼────────────┐
  │ FetchService│  │ ScheduleStore  │
  │ (URLSession)│  │ (UserDefaults) │
  │ football-   │  │ cached matches │
  │ data.org    │  │ standings      │
  └─────────────┘  └────────────────┘
```

---

## 6. Menu Bar Label

The compact label in the menu bar area. It has three states:

### 6.1 No match today

```
⚽ FWC
```

Just the icon + abbreviation. Subtle, minimal.

### 6.2 Upcoming match today (latest match first)

```
⚽ BRA vs ARG · 3:00 PM
```

Shows the next match. If the user has a favorite team, that match is
prioritized; otherwise, the closest match to kickoff is shown.

### 6.3 Match in progress (live)

```
⚽ BRA 2 - 1 ARG · 67'
```

Live score with current minute. Polls every N seconds (configurable).

### 6.4 Goal animation

When a score changes (goal detected by comparing previous poll to current):

- The score text briefly pulses/flashes.
- A tiny ⚨ emoji slides left-to-right across the menu bar text area.
- Animation duration: ~1.5 seconds.
- Lightweight: pure SwiftUI `.transition` + `.animation`.

### 6.5 Multiple simultaneous matches

When multiple matches are live simultaneously, show the one closest to
a goal (highest elapsed time relative to 90 minutes). The panel shows
all live matches.

---

## 7. Menu Bar Panel (on click)

The expanded panel shown when the menu bar item is clicked.

### 7.1 Layout

```
┌─────────────────────────────────┐
│  FIFA WORLD CUP 2026            │  ← header
│  ─────────────────────────────  │
│  [Today] [Yesterday] [Tomorrow] │  ← tab row (horizontal scroll)
│  [Full Schedule] [Standings]    │
│  ─────────────────────────────  │
│  ← June 15, 2026 →             │  ← date navigation (for schedule)
│                                 │
│  🇧🇷 Brazil  2 - 1  Argentina 🇦🇷 │  ← match card (live)
│  ⏱ 67'  ·  Group A             │
│                                 │
│  🇩🇪 Germany  3 - 0  Japan 🇯🇵   │  ← match card (finished)
│  ✅ FT  ·  Group E             │
│                                 │
│  🇬🇧 England vs 🇮🇹 Italy       │  ← match card (upcoming)
│  ⏰ 9:00 PM  ·  Group D        │
│  ─────────────────────────────  │
│  🔄 Sync                        │  ← manual sync button
│  ⚙️ Settings                    │  ← API key, poll interval, favorite team
│  ❌ Quit                        │
└─────────────────────────────────┘
```

### 7.2 Tabs

| Tab               | Content                                                                             |
| ----------------- | ----------------------------------------------------------------------------------- |
| **Today**         | All matches for today, chronological. Live matches at top with pulsing indicator.   |
| **Yesterday**     | Yesterday's results, chronological.                                                 |
| **Tomorrow**      | Tomorrow's scheduled matches.                                                       |
| **Full Schedule** | Calendar-style view of the whole tournament. Date picker on left, matches on right. |
| **Standings**     | Group tables (A–H). Points, GD, W/D/L.                                              |

### 7.3 Match Card

Each match is a compact card showing:

- Team flags (emoji or small images)
- Team names (abbreviated: `BRA`, `ARG`)
- Score (if applicable)
- Match minute (if live) or status (`FT`, `SCHEDULED`, `TIME`)
- Group label
- Kickoff time (if upcoming)

### 7.4 Footer Actions

| Button       | Action                                                                                              |
| ------------ | --------------------------------------------------------------------------------------------------- |
| **Sync**     | Force an immediate data fetch from football-data.org. Shows a brief spinner.                        |
| **Settings** | In-panel settings: API key field, poll interval slider, favorite team picker. (No separate window.) |
| **Quit**     | `NSApplication.shared.terminate(nil)`                                                               |

---

## 8. Data Source — football-data.org

### 8.1 API Details

- **Base URL:** `https://api.football-data.org/v4/`
- **Auth:** `X-Auth-Token` header (free registration).
- **Free tier:** 10 requests/minute.
- **Competition code:** `WC` (FIFA World Cup).
- **Season:** `2026`.

### 8.2 Key Endpoints

| Endpoint                                                                | Purpose                 |
| ----------------------------------------------------------------------- | ----------------------- |
| `GET /v4/competitions/WC/matches?matchday=N`                            | Matches for a matchday  |
| `GET /v4/competitions/WC/matches?dateFrom=YYYY-MM-DD&dateTo=YYYY-MM-DD` | Matches in a date range |
| `GET /v4/competitions/WC/standings`                                     | Group standings         |
| `GET /v4/matches/{id}`                                                  | Single match detail     |

### 8.3 Match Status Values

| Status      | Meaning                      |
| ----------- | ---------------------------- |
| `SCHEDULED` | Not yet started              |
| `TIMED`     | Kickoff time set             |
| `IN_PLAY`   | Currently playing            |
| `PAUSED`    | Half-time / extra time break |
| `FINISHED`  | Full time                    |
| `POSTPONED` | Delayed                      |
| `CANCELLED` | Not happening                |

### 8.4 Polling Strategy

| State                         | Interval              | Rationale                                       |
| ----------------------------- | --------------------- | ----------------------------------------------- |
| No live matches               | Check at **midnight** | Minimal waste; auto-detect next day's matches   |
| Match in progress             | **60 seconds**        | Real-time score updates (configurable, min 60s) |
| Match starting soon (< 5 min) | **30 seconds**        | Catch kickoff                                   |
| User clicks **Sync**          | Immediate             | Manual override                                 |

The user can change the live-polling interval in settings (minimum: 60 seconds).
Default: 60 seconds.

### 8.5 Data Caching

- Store today's, yesterday's, and tomorrow's match data in memory.
- Store the full tournament schedule in `UserDefaults` (encoded).
- On app launch, fetch today's matches and today's standings.
- Standings refresh every 5 minutes or on manual sync.

---

## 9. Goal Animation

### 9.1 Detection

Compare the score from the previous poll to the current poll for each live
match. If `homeScore` or `awayScore` increased, a goal was scored.

### 9.2 Animation

A tiny ⚨ text slides from left to right across the menu bar label area.
Implementation:

- Overlay a `Text("⚽")` with `.offset(x: -20)` → `.offset(x: +200)` animation.
- Duration: 1.5 seconds.
- Ease: `.easeInOut`.
- The menu bar score text pulses with a brief scale animation.

### 9.3 Memory

The animation view is created on-demand and destroyed after completion.
No persistent animation state.

---

## 10. Dynamic Team-Color Theming

The menu bar and panel use team colors from the currently featured match.

- **Home team color** → primary accent (menu bar text highlight, card borders).
- **Away team color** → secondary accent.
- Default (no featured match) → FIFA purple (`#56006B`) or system accent.
- Color blending: use the team's primary color at 15–20% opacity for card
  backgrounds, 100% for active-state highlights.

Team color mapping is a hardcoded dictionary of FIFA member nations.

---

## 11. Performance Constraints

| Metric                  | Target                 |
| ----------------------- | ---------------------- |
| RAM usage               | < 20 MB at idle        |
| CPU during idle         | < 0.1%                 |
| CPU during live polling | < 1%                   |
| Network requests        | Max 10/min (API limit) |
| App launch time         | < 500ms                |

### 11.1 Optimization Strategies

- Pause all timers when no live matches are in progress.
- No background fetch — app only polls when active (user opened it).
- No Combine pipelines — direct `@Observable` bindings.
- Minimal memory: no image downloads (emoji flags only).
- Network responses are lightweight JSON; no large payloads.
- Day-rollover detection (like the prayer app) instead of continuous timers.

---

## 12. Info.plist

```xml
<key>LSUIElement</key>
<true/>
```

No Dock icon, no main window. Menu bar agent only.

---

## 13. Distribution & Auto-Update

- **GitHub Releases** (unsigned for dev, Developer ID + notarization for release).
- No App Store.
- **Sparkle** for auto-updates — industry-standard macOS update framework.
- Sparkle feed URL → GitHub Releases API (`/repos/{owner}/fifawc-scores/releases/latest`).
- "Check for Updates" button in Settings tab.
- Version consistency: `MARKETING_VERSION` in `project.yml` must match git tag.
- CI/CD pipeline: GitHub Actions builds, signs, notarizes, publishes on tag push.
- No Homebrew initially (add later if popular).

---

## 14. File Structure

```
fifawc-scores/
├── CLAUDE.md              # Agent guidance
├── spec.md                # This file — implementation contract
├── plan.md                # Milestones and development order
├── design.md              # UI/UX design decisions
├── api.md                 # API research and data source docs
├── notes.md               # Raw ideas, inspiration, future features
├── project.yml            # XcodeGen project definition
├── Sources/
│   ├── App/
│   │   ├── FIFAWCScoresApp.swift          # @main entry
│   │   └── AppDelegate.swift          # NSApplicationDelegate for menu bar
│   ├── Models/
│   │   ├── Match.swift                # Match data model
│   │   ├── Team.swift                 # Team data model
│   │   ├── Standing.swift             # Group standing model
│   │   ├── MatchStatus.swift          # Enum for match states
│   │   └── TeamColors.swift           # Team → color mapping
│   ├── Services/
│   │   ├── FetchService.swift         # football-data.org API client
│   │   ├── MatchStore.swift           # Central state (@Observable)
│   │   └── PollController.swift       # Timer-based polling logic
│   ├── Views/
│   │   ├── MenuBarLabel.swift         # Compact menu bar view
│   │   ├── MenuBarPanel.swift         # Expanded panel on click
│   │   ├── MatchCard.swift            # Individual match display
│   │   ├── GoalAnimation.swift        # ⚽ slide animation
│   │   ├── StandingsView.swift        # Group tables
│   │   ├── ScheduleView.swift         # Full schedule calendar
│   │   └── SettingsView.swift         # In-panel settings
│   └── Resources/
│       ├── Assets.xcassets/
│       └── Info.plist
└── Tests/
    └── ...
```
