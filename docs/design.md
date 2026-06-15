# Design Decisions — FIFAWC Scores

## Color Scheme: Dynamic Team Theming

### Primary Approach

Colors adapt to the currently featured match:

- **Home team primary color** → accent for menu bar text, card borders, active states
- **Away team primary color** → secondary accent
- Default (no featured match or idle) → FIFA purple (`#56006B`)

### Team Color Palette (FIFA WC 2026 Participants)

| Team            | Primary                | Secondary           |
| --------------- | ---------------------- | ------------------- |
| 🇦🇷 Argentina    | `#75AADB` (light blue) | `#FFFFFF` (white)   |
| 🇧🇷 Brazil       | `#FFDF00` (yellow)     | `#009C3B` (green)   |
| 🇫🇷 France       | `#002395` (blue)       | `#ED2939` (red)     |
| 🇩🇪 Germany      | `#000000` (black)      | `#DD0000` (red)     |
| 🇪🇸 Spain        | `#AA151B` (red)        | `#F1BF00` (yellow)  |
| 🇬🇧 England      | `#FFFFFF` (white)      | `#CF081F` (red)     |
| 🇵🇹 Portugal     | `#006600` (green)      | `#FF0000` (red)     |
| 🇳🇱 Netherlands  | `#FF6600` (orange)     | `#21468B` (blue)    |
| 🇧🇪 Belgium      | `#000000` (black)      | `#FDDA24` (yellow)  |
| 🇮🇹 Italy        | `#008C45` (green)      | `#CD212A` (red)     |
| 🇺🇾 Uruguay      | `#5DCBEF` (sky blue)   | `#FCE300` (yellow)  |
| 🇨🇴 Colombia     | `#FCD116` (yellow)     | `#003893` (blue)    |
| 🇲🇽 Mexico       | `#006847` (green)      | `#CE1126` (red)     |
| 🇺🇸 USA          | `#3C3B6E` (navy)       | `#B22234` (red)     |
| 🇯🇵 Japan        | `#BC002D` (red)        | `#FFFFFF` (white)   |
| 🇰🇷 South Korea  | `#003478` (blue)       | `#C60C30` (red)     |
| 🇦🇺 Australia    | `#00843D` (green)      | `#00008B` (navy)    |
| 🇲🇦 Morocco      | `#C1272D` (red)        | `#006233` (green)   |
| 🇸🇳 Senegal      | `#00853F` (green)      | `#EF3340` (red)     |
| 🇨🇲 Cameroon     | `#007A5E` (green)      | `#CE1126` (red)     |
| 🇳🇬 Nigeria      | `#008751` (green)      | `#FFFFFF` (white)   |
| 🇬🇭 Ghana        | `#006B3F` (green)      | `#FCD116` (yellow)  |
| 🇵🇱 Poland       | `#FFFFFF` (white)      | `#DC143C` (crimson) |
| 🇨🇭 Switzerland  | `#FF0000` (red)        | `#FFFFFF` (white)   |
| 🇩🇰 Denmark      | `#C8102E` (red)        | `#FFFFFF` (white)   |
| 🇸🇪 Sweden       | `#006AA7` (blue)       | `#FECC02` (yellow)  |
| 🇨🇷 Costa Rica   | `#00238C` (blue)       | `#EF0B29` (red)     |
| 🇵🇾 Paraguay     | `#D52B1E` (red)        | `#0038A8` (blue)    |
| 🇺🇿 Uzbekistan   | `#1EB53A` (green)      | `#0099B5` (teal)    |
| 🇸🇦 Saudi Arabia | `#006C35` (green)      | `#FFFFFF` (white)   |
| 🇮🇷 Iran         | `#239F40` (green)      | `#DA0000` (red)     |
| 🇮🇶 Iraq         | `#CE1126` (red)        | `#007A3D` (green)   |
| 🇯🇴 Jordan       | `#000000` (black)      | `#CE1126` (red)     |
| 🇦🇪 UAE          | `#FF0000` (red)        | `#00732F` (green)   |
| 🇶🇦 Qatar        | `#8D1B3D` (maroon)     | `#FFFFFF` (white)   |
| 🇧🇭 Bahrain      | `#CE1126` (red)        | `#FFFFFF` (white)   |
| 🇴🇲 Oman         | `#007A3D` (green)      | `#C8102E` (red)     |
| 🇱🇧 Lebanon      | `#EE161F` (red)        | `#00A551` (green)   |
| 🇦🇺 Australia    | `#00843D` (green)      | `#FFCD00` (gold)    |
| 🇳🇿 New Zealand  | `#000000` (black)      | `#FFFFFF` (white)   |
| 🇨🇦 Canada       | `#FF0000` (red)        | `#FFFFFF` (white)   |
| 🇨🇺 Cuba         | `#002A8F` (blue)       | `#CF142B` (red)     |
| 🇯🇲 Jamaica      | `#009B3A` (green)      | `#FED100` (yellow)  |
| 🇭🇹 Haiti        | `#00209F` (blue)       | `#D21034` (red)     |
| 🇵🇦 Panama       | `#003DA5` (blue)       | `#C8102E` (red)     |
| 🇬🇹 Guatemala    | `#4997D0` (blue)       | `#4997D0` (blue)    |
| 🇸🇻 El Salvador  | `#0047AB` (blue)       | `#0047AB` (blue)    |
| 🇭🇳 Honduras     | `#0073CF` (blue)       | `#0073CF` (blue)    |
| 🇳🇮 Nicaragua    | `#0067C6` (blue)       | `#0067C6` (blue)    |
| 🇨🇼 Curaçao      | `#00A5D9` (blue)       | `#F9D616` (yellow)  |

### Color Application Rules

1. **Menu bar label**: Team primary color for text, or `.primary` (system) when idle.
2. **Panel header**: Gradient from home team primary → away team primary (subtle).
3. **Match card borders**: Home team color at 20% opacity.
4. **Live indicator**: Pulsing dot in home team primary color.
5. **Goal animation**: Football emoji in team primary color.
6. **Standings header**: FIFA purple (`#56006B`) — neutral.
7. **Fallback**: If team not in dictionary, use `.accentColor` (system).

---

## Menu Bar Label Design

### Typography

- SF Pro Text, 13px (standard menu bar size).
- `.monospacedDigit()` for scores and countdowns.

### Icon

- `Image(systemName: "soccerball")` — SF Symbol, not emoji.
- `Text("⚽")` emoji consumed the full status item width and hid the label text.
- SF Symbol renders correctly alongside the text label.

### States

All states render as: `[soccerball]` SF Symbol + text.

#### Idle (no match today)

```
⚽ FWC
```

#### Upcoming (today only)

```
⚽ BRA vs ARG · 3:00 PM
```

#### Live

```
⚽ BRA 2 - 1 ARG · 67'
```

- Minute ticks every 60s via `store.minuteTick: Date` on MatchStore.

#### Half-time

```
⚽ BRA 0 - 0 ARG · HT
```

- `effectiveStatus == .paused` → display `HT` instead of minute counter.

#### Finished

```
⚽ SWE 5 - 1 TUN · FT
```

#### Goal (2-second flash)

```
⚽ GOAL!
```

- Label text flips to `GOAL!` for exactly 2 seconds, then auto-reverts.
- `triggerGoal()` on MatchStore sets `goalScored = true` + schedules 2s reset.
- **No icon animation** — `.symbolEffect(.bounce)`, `.scaleEffect`, offset/opacity
  overlays all fail silently inside MenuBarExtra label context.

### Real-Time Ticking

- `minuteTick: Date` on MatchStore — updated every 60s by a `Task.sleep` loop.
- MenuBarLabel reads `store.minuteTick` to force SwiftUI re-renders.
- `TimelineView` is explicitly NOT used — it hangs MenuBarExtra label on macOS.

### Hallucination Prevention

- `allMatches` scoped to 3-day window (yesterday/today/tomorrow) — Schedule tab
  data (±7 days) never bleeds into `featuredMatch` or `liveMatches`.
- `featuredMatch` priority: live → today-upcoming → recent-finished → nil.
- Upcoming matches restricted to **today only** — never shows future days.

---

## Panel Design

### Dimensions

- Width: 340px (fixed, like the prayer app's 300px)
- Height: Dynamic based on content
- Max height: 500px (scrollable)

### Background

- `.ultraThinMaterial` with backdrop blur (native macOS material)
- Rounded corners: 11px (matches macOS system panels)

### Match Card Layout

```
┌──────────────────────────────────┐
│  🇧🇷  BRA  2 - 1  ARG  🇦🇷       │
│  ⏱ 67'  ·  Group A              │
└──────────────────────────────────┘
```

- 60px height per card
- Teams: abbreviated (3-letter code) with flag emoji
- Score: centered, bold, monospaced
- Status line: minute/status + group

### Tab Design

- Horizontal pill-style tabs
- Active tab: filled with accent color
- Inactive: text only with hover highlight
- Scrollable if overflow

### Footer

- Three buttons: Sync, Settings, Quit
- Each as a full-width row with icon + label
- Hover highlight (like the prayer app's `MenuRowHighlight`)

---

## Goal Animation Design

### Concept

When a goal is detected, the menu bar label text flips to `GOAL!` for 2 seconds,
then auto-reverts to the live score. No icon animation, no sliding elements —
text-state flip is the only approach that works in MenuBarExtra label context.

### Implementation

1. Score change detected in `MatchStore.detectGoals()` (compares previous scores).
2. `triggerGoal()` sets `goalScored = true`.
3. `MenuBarLabel` reads `store.goalScored` → text switches to `"GOAL!"`.
4. After exactly 2 seconds, `Task.sleep(for: .seconds(2.0))` expires → `goalScored = false`.
5. Label text reverts to the normal `labelText(at:)` output.

### What Failed

- `.symbolEffect(.bounce)` — no effect in MenuBarExtra label
- `.scaleEffect` + `.animation(value:)` — no effect in MenuBarExtra label
- Sliding ⚽ offset + opacity overlay — no effect in MenuBarExtra label
- `TimelineView` wrapping — hangs the app entirely

### Testing

- `#if DEBUG` "Test Goal" button (SF Symbol `soccerball`) in MenuBarPanel footer calls `store.triggerGoal()`.

---

## Standings View Design

### Group Table Layout

```
┌──────────────────────────────────┐
│  GROUP A                        │
│  # Team       P  W  D  L  Pts   │
│  1 Brazil     3  2  1  0   7    │
│  2 Argentina  3  2  0  1   6    │
│  3 Uruguay    3  1  1  1   4    │
│  4 Saudi Arb  3  0  0  3   0    │
└──────────────────────────────────┘
```

- Groups A through H
- Compact table: position, team, P, W, D, L, Pts
- Highlight qualified teams (top 2) with green dot
- Scrollable if many groups

---

## Accessibility

- VoiceOver labels for all interactive elements.
- Match cards read as: "Brazil two, Argentina one, 67 minutes, Group A".
- Tab labels are self-descriptive.
- Sync button has clear state feedback.

---

## Dark Mode Support

- All colors work in both light and dark mode.
- Team colors are applied with appropriate opacity for each mode.
- Panel background uses `.ultraThinMaterial` which adapts automatically.
- Text uses `.primary`, `.secondary`, `.tertiary` semantic colors.
