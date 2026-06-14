# Raw Ideas & Notes — WC Scores

## Inspiration Sources

### prayer-times-macos (tareq1988)

- Menu bar agent architecture
- `MenuBarExtra` with `.window` style
- 1-second tick with `beginActivity` to prevent App Nap
- PrayerClock as `@Observable` driving everything
- MenuBarLabel (compact) + MenuBarPanel (expanded)
- XcodeGen for project generation
- Sparkle for updates (we skip this in v1)
- LSUIElement = true for no Dock icon

### Key Takeaways

- The prayer app's tick-based approach is solid for live data
- `@Observable` is perfect for this kind of reactive state
- Panel layout is clean and macOS-native
- Footer actions pattern (Settings, Sync, Quit) works well

---

## User Decisions (Locked In)

1. **Featured match priority**: Show the match closest to a goal (highest elapsed time)
2. **Panel views**: Previous day, Today, Tomorrow, Full Schedule, Standings
3. **Goal animation**: Tiny ⚨ slides left-to-right across menu bar text (keep it simple)
4. **Polling**:
   - Live matches: 60 seconds (configurable, min 60s)
   - No matches: auto-check at midnight (NOT every hour)
   - Manual sync button in panel
5. **Color scheme**: Dynamic team colors from featured match
6. **Tech**: Swift 6, SwiftUI, MenuBarExtra, URLSession, XcodeGen, macOS 14+
7. **Dependencies**: ZERO third-party packages (pure native)
8. **No auto-start**: User opens manually, app stays in menu bar
9. **API key**: User-configurable in Settings tab (not hardcoded)
   - Stored in UserDefaults via `@AppStorage`
   - "No API key" error shown in panel header (non-blocking)
   - Link to football-data.org registration in Settings
10. **Full Schedule tab**: Added with date picker, shows all tournament matches grouped by date
11. **Goal animation**: Simple text slide first, no complex animations for v1

---

## Future Ideas (Post v1)

### Notifications

- "Match starting in 5 minutes" local notification
- "GOAL! Brazil scored!" notification (optional)
- Configurable per-team notifications

### Favorite Team

- User picks their favorite team in settings
- Menu bar always shows that team's matches first
- Highlight favorite team's matches in the panel

### Golden Boot Tracker

- Show top scorers in a tab
- Live update as goals are scored

### Knockout Bracket View

- Visual bracket for Round of 16 → Final
- Tap to see match details

### Widget (WidgetKit)

- Small widget showing next match
- Medium widget showing today's results
- Lock screen widget

### Multiple Favorite Teams

- Follow multiple teams
- Menu bar cycles through them

### Sound Effects

- Optional goal sound (subtle chime)
- Match kickoff sound

### Share Results

- Share match result as image
- Copy score to clipboard

### Internationalization

- Arabic, Turkish, Bengali (following prayer app's languages)
- RTL support

### Homebrew Cask

- Package for `brew install --cask wc-scores`

---

## Technical Notes

### Memory Management

- Don't download team logos — use emoji flags only
- Don't keep more than 3 days of match data in memory
- Standings: only keep current tournament data
- No background fetch — only poll when app is active

### Network Optimization

- football-data.org free tier: 10 req/min
- During idle: 0 requests/min
- During live: 1 request/min (60s interval)
- On sync: 1-2 requests (matches + standings)
- Cache standings for 5 minutes

### Day Rollover

- Like the prayer app, detect when the civil day changes
- Fetch new day's matches on rollover
- Don't use continuous timers — use midnight check

### App Nap Prevention

- Only prevent App Nap during live matches
- Use `beginActivity` with `.idleSystemSleepDisabled`
- Release activity when match ends

---

## Open Questions (Resolved)

1. ~~Which match to show when multiple are live?~~ → Closest to goal
2. ~~What views should the panel have?~~ → Previous, Today, Tomorrow, Full Month, Standings
3. ~~Should goal animation be complex?~~ → No, keep it simple (tiny slide)
4. ~~What poll interval?~~ → 60s default, configurable, min 60s
5. ~~What color scheme?~~ → Dynamic team colors
6. ~~Should we use Alamofire?~~ → No, URLSession is enough
7. ~~Should we have a settings window?~~ → No, in-panel settings only
8. ~~Should the app auto-start?~~ → No, user opens manually

---

## FIFA World Cup 2026 Quick Facts

- Host: USA, Canada, Mexico (first tri-host)
- Teams: 48 (expanded from 32)
- Groups: A through H (8 groups of 6... wait, 12 groups of 4)
- Actually: 12 groups of 4 = 48 teams
- Group stage: June 11 – June 27, 2026
- Round of 32: June 29 – July 3
- Round of 16: July 4 – July 6
- Quarter-finals: July 9 – July 11
- Semi-finals: July 14 – July 15
- Third place: July 18
- Final: July 19, 2026
- Total matches: 104

---

## App Name Options

- **WC Scores** ✅ (short, clear)
- **MatchDay** (generic, could conflict)
- **GoalBar** (fun, punny)
- **KickOff** (catchy)
- **Pitch** (minimal)
- **⚽ WC** (what shows in menu bar)

→ Going with **WC Scores** as project name, **⚽ WC** as menu bar label.
