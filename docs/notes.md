# Raw Ideas & Notes — FIFAWC Scores

## Inspiration Sources

### prayer-times-macos (tareq1988)

- Menu bar agent architecture
- `MenuBarExtra` with `.window` style
- 1-second tick with `beginActivity` to prevent App Nap
- PrayerClock as `@Observable` driving everything
- MenuBarLabel (compact) + MenuBarPanel (expanded)
- XcodeGen for project generation
- Sparkle for updates (adopted in M15 — was "skip in v1", now planned)
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
3. **Goal animation**: Text flips to `GOAL!` for 2 seconds, auto-reverts. No icon animation (`.symbolEffect`, `.scaleEffect` all fail in MenuBarExtra label context). `TimelineView` permanently dropped — hangs the app.
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
11. **Goal animation**: `GOAL!` text flip for 2s. Simple, no complex animations. All animation modifiers fail in MenuBarExtra label — text-state flip is the only viable approach.
12. **SF Symbol replaces emoji**: `Text("⚽")` consumed full status item width. `Image(systemName: "soccerball")` renders correctly alongside text.
13. **`minuteTick: Date`** on MatchStore: Task.sleep(60s) loop drives live minute counter. `TimelineView` explicitly avoided — hangs MenuBarExtra labels.
14. **`allMatches` scoped to 3-day window**: Prevents Schedule tab ±7d data from bleeding into `featuredMatch` and showing future-day matches in menu bar.
15. **`featuredMatch` priority**: live → today-upcoming → recent-finished → nil. Upcoming restricted to today only.

### Phase 2 Decisions (Auto-Update + CI/CD)

12. **Auto-update via Sparkle**: Industry-standard framework (VS Code, Discord, Rectangle all use it). Handles version check, download, Ed25519 signature verify, app replace, restart. The one allowed third-party dependency.
13. **GitHub Releases as update feed**: Free, native GitHub API. Sparkle reads `https://api.github.com/repos/{owner}/fifawc-scores/releases/latest` to check for new versions.
14. **Tag-driven CI/CD**: Push a git tag → GitHub Actions builds → signs → notarizes → publishes. No manual build steps.
15. **Version consistency**: `MARKETING_VERSION` in `project.yml` MUST match the git tag. Prevents the "just installed latest but still sees update available" bug.
16. **Sparkle is NOT bloated**: It's a single framework (~2MB), adds no runtime overhead when not checking for updates. Acceptable under the "tiny footprint" constraint.
17. **Test gate**: CI runs tests before publishing. No release without green tests.

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

- Package for `brew install --cask fifawc-scores`

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

### Auto-Update Architecture (Phase 2)

**How Sparkle works under the hood:**

1. App bundles Sparkle framework + `SUFeedURL` in Info.plist
2. On launch or manual "Check for Updates" click:
   - Sparkle reads `CFBundleShortVersionString` (e.g. "1.0.0")
   - Fetches `https://api.github.com/repos/{owner}/fifawc-scores/releases/latest`
   - Parses the release tag (e.g. "v1.1.0")
   - Compares: "1.0.0" < "1.1.0" → update available
3. Shows dialog with release notes + "Download" button
4. Downloads `.zip` from the release assets
5. Verifies Ed25519 cryptographic signature (prevents tampering)
6. Replaces old `.app` with new one, restarts app

**Version bug prevention:**

- The "false update available" bug happens when:
  - Tag says `v1.1.0` but `MARKETING_VERSION` is still `1.0.0`
  - User downloads `v1.1.0`, replaces app, but old app was still running
  - Solution: always quit old app before replacing, bump version BEFORE tagging

**CI/CD pipeline (GitHub Actions):**

- Trigger: `git tag v1.1.0 && git push origin main --tags`
- Runner: `macos-14` (Apple Silicon)
- Steps: parse → build → archive → sign → notarize → staple → release
- Secrets: Developer ID certificate + Apple notarization credentials

**What the user sees (end-to-end flow):**

1. Developer runs `./scripts/bump-version.sh 1.1.0`
2. Script updates version, commits, tags
3. Developer pushes: `git push origin main --tags`
4. GitHub Actions builds and publishes to GitHub Releases
5. User's app checks for updates → sees v1.1.0 → clicks Download
6. Sparkle downloads, verifies, replaces, restarts
7. User is now on v1.1.0. App shows "You're up to date!" on next check

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

- **FIFAWC Scores** ✅ (short, clear)
- **MatchDay** (generic, could conflict)
- **GoalBar** (fun, punny)
- **KickOff** (catchy)
- **Pitch** (minimal)
- **⚽ FWC** (what shows in menu bar)

→ Going with **FIFAWC Scores** as project name, **⚽ FWC** as menu bar label.
