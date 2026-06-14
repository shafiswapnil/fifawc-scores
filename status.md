# Project Status — WC Scores

> This file tracks the current stage of the project for any agent or LLM
> working on it. Always update this file when milestones are completed.

## Current Stage

**Phase 1: Project Scaffolding (M1)** — 🔄 IN PROGRESS

## Milestone Tracker

| #   | Milestone                   | Status         | Notes                                                |
| --- | --------------------------- | -------------- | ---------------------------------------------------- |
| M1  | Project Scaffolding         | 🔄 In Progress | XcodeGen setup, dirs, Info.plist, empty menu bar app |
| M2  | Data Models                 | ⬜ Not Started | Match, Team, Standing, MatchStatus, TeamColors       |
| M3  | API Client (FetchService)   | ⬜ Not Started | football-data.org integration                        |
| M4  | MatchStore (Central State)  | ⬜ Not Started | @Observable driving all views                        |
| M5  | PollController (Scheduling) | ⬜ Not Started | Timer-based polling logic                            |
| M6  | MenuBarLabel                | ⬜ Not Started | Compact menu bar view                                |
| M7  | Goal Animation              | ⬜ Not Started | Tiny ⚨ slide across menu bar                         |
| M8  | MenuBarPanel                | ⬜ Not Started | Tabbed panel with match cards                        |
| M9  | Settings (In-Panel)         | ⬜ Not Started | Poll interval, favorite team                         |
| M10 | Polish & Testing            | ⬜ Not Started | Memory/CPU profiling, edge cases                     |

## Key Decisions Log

| Date       | Decision                                  | Rationale                                |
| ---------- | ----------------------------------------- | ---------------------------------------- |
| 2026-06-15 | football-data.org as primary API          | Free, reliable, live scores, WC support  |
| 2026-06-15 | Zero third-party dependencies             | Tiny footprint, URLSession sufficient    |
| 2026-06-15 | 60s poll interval (configurable, min 60s) | Balance between freshness and API limits |
| 2026-06-15 | Midnight auto-check when idle             | No polling waste when no matches         |
| 2026-06-15 | Dynamic team colors                       | Cool, contextual theming                 |
| 2026-06-15 | Simple goal animation first               | Don't overcomplicate v1                  |

## Architecture Quick Reference

- **App**: SwiftUI `MenuBarExtra` (.window style), macOS 14+
- **State**: `@Observable` MatchStore drives all views
- **API**: football-data.org v4, URLSession, X-Auth-Token header
- **Polling**: Timer-based, state machine (IDLE → SCHEDULED → LIVE → IDLE)
- **Build**: XcodeGen (`project.yml`), Swift 6, strict concurrency

## Agent Instructions

When working on this project:

1. Read this file first to know the current stage
2. Check `docs/spec.md` for the full implementation contract
3. Check `docs/plan.md` for the milestone details
4. Update this file when you complete a milestone or make a key decision
5. Follow conventions in CLAUDE.md
