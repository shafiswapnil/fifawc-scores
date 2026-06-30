# Changelog — FIFAWC Scores

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [1.1.0] — 2026-06-30

### Changed

- **Panel v2 production-safe rewrite** — rebuilt MenuBarPanel from scratch.
  Solid `Theme.panelBackground` dark fill (no material overlays) works
  identically in Debug and Release builds.
- **DarkModeBridge restored** — AppKit `NSViewRepresentable` that forces
  `darkAqua` appearance on the hosting window. Confirmed safe when no
  material/glass overlays are present (the previous failures were caused
  by `.ultraThinMaterial` conflicts, not the bridge itself).
- **Panel spacing restructured for macOS rounded corners** — asymmetric
  padding (10px header top, 10px footer bottom, 14px tab trailing) to
  clear the system window's ~10px corner radius without wasting space.
- **Content alignment** — content now anchors to the top of the panel
  (was previously centered due to `.layoutPriority(-1)`).

### Removed

- **`MenuBarPanelLegacy.swift`** — old panel code deleted.
- **Material overlays** — zero `.ultraThinMaterial` / `.glassEffect` usage
  in the panel. Solid colors only for production safety.
- **`.preferredColorScheme(.dark)` on panel** — confirmed non-functional in
  `MenuBarExtra(.window)`. DarkModeBridge is the sole dark-mode mechanism.

### Fixed

- **TextField dark mode in Settings** — search field and API key input now
  render with correct light-on-dark text (was broken when DarkModeBridge
  was removed).
- **⚙️ gear icon clipping** — tab row trailing padding prevents the settings
  icon from being cut off by the ScrollView edge.
- **Blank space above/below panel content** — system menu bar margins no
  longer create visual gaps.

[1.1.0]: https://github.com/shafiswapnil/fifawc-scores/compare/v1.0.2...v1.1.0

## [1.0.1] — 2026-06-16

### Fixed

- **Sparkle auto-update "Unable to Check For Updates" error on launch** —
  EdDSA (Ed25519) signing key pair now generated and configured. Sparkle
  requires EdDSA to verify update integrity. Without it, the updater refused
  to start. Public key (`SUPublicEDKey`) added to Info.plist, private key
  configured as GitHub Actions secret for CI signing.

### Changed

- **CI release pipeline now signs update zips with EdDSA** — `release.yml`
  downloads Sparkle's `sign_update` tool, signs the `.zip` with the private
  key, and embeds the signature in `appcast.xml` so Sparkle can verify
  downloads on the client side.
- **`.gitignore` updated** — blocks `*.pem` files to prevent accidental
  private key commits.

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
