# CLAUDE.md

Guidance for working in this repository.

## What this is

**WC Scores** — a native, lightweight macOS menu bar app showing FIFA World
Cup 2026 match schedules, live scores, and goal animations. Menu bar agent
(no Dock icon). All interaction happens in the menu bar — no main window.

## Layout

```
CLAUDE.md               # This file — agent guidance
status.md               # Project stage tracking for all agents/LLMs
prompts.md              # User's prompt log
docs/
  spec.md               # The implementation contract (source of truth)
  plan.md               # Milestones and development order
  design.md             # UI/UX design decisions, color schemes, animations
  api.md                # Data source research, API endpoints, polling strategy
  notes.md              # Raw ideas, inspiration, future features
project.yml             # XcodeGen project definition (app target)
WCSCORES.xcodeproj      # GENERATED from project.yml — git-ignored, do not edit
Sources/
  App/                  # @main entry, app lifecycle
  Models/               # Data models (Match, Team, Score, etc.)
  Services/             # Networking, data fetching, scheduling
  Views/                # SwiftUI views (MenuBarLabel, MenuBarPanel, etc.)
  Resources/            # Assets, icons
```

## Build, run, test

```bash
# Regenerate the Xcode project after editing project.yml
xcodegen generate

# Build the app
xcodebuild -project WCSCORES.xcodeproj -scheme WCSCORES \
  -configuration Debug -destination 'platform=macOS' \
  CODE_SIGNING_ALLOWED=NO build
```

## Key constraints (non-negotiable)

- **Tiny RAM/CPU footprint.** No heavy frameworks, no bloated dependencies.
- **Zero login items.** User opens manually; app stays in menu bar once launched.
- **No Dock icon.** `LSUIElement = true`. Menu bar agent only.
- **Minimal third-party packages.** Prefer native `URLSession` over Alamofire.
- **macOS 14+ deployment target.** Universal binary.
- **No settings window in v1.** Everything in the menu bar panel.
- **All scheduling logic respects the chosen poll interval** (min 60s).

## Conventions

- Swift 6, strict concurrency (`SWIFT_STRICT_CONCURRENCY=complete`).
- SwiftUI-first, minimal AppKit bridging only where SwiftUI gaps exist.
- `@Observable` for state management (no Combine publishers).
- `URLSession` for networking (no third-party HTTP libraries).
- Conventional Commits (`feat:`, `fix:`, `chore:`, `docs:`).
- XcodeGen for project generation (`project.yml`).
