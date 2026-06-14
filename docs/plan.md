# Development Plan — WC Scores

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

- Compact menu bar view with three states:
  - No match: `⚽ WC`
  - Upcoming: `⚽ BRA vs ARG · 3:00 PM`
  - Live: `⚽ BRA 2 - 1 ARG · 67'`
- Dynamic team-color accent
- Live match minute counter

### M7: Goal Animation

- Score change detection (compare previous poll to current)
- Tiny ⚨ slides left-to-right across menu bar text
- Duration: 1.5s, ease-in-out
- Score text pulse effect
- On-demand creation, auto-destroy

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

---

## Build Order

```
M1 → M2 → M3 → M4 → M5 → M6 → M7 → M8 → M9 → M10
```

Each milestone is independently buildable and testable.
