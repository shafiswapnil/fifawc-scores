# API Research — FIFA World Cup 2026 Data Sources

## Primary: football-data.org

### Overview

- RESTful football data API
- Free tier: 10 requests/minute
- Covers FIFA World Cup (competition code: `WC`)
- JSON responses, well-documented

### Authentication

```
Header: X-Auth-Token: YOUR_API_KEY
```

Free registration at https://www.football-data.org/client/register

### Base URL

```
https://api.football-data.org/v4/
```

### Key Endpoints

#### Get Today's Matches

```
GET /v4/matches
Header: X-Auth-Token: {key}
```

Returns all matches scheduled for today across subscribed competitions.

#### Get Matches by Date Range

```
GET /v4/competitions/WC/matches?dateFrom=2026-06-14&dateTo=2026-06-14
```

#### Get Matches by Matchday

```
GET /v4/competitions/WC/matches?matchday=1
```

#### Get Standings

```
GET /v4/competitions/WC/standings
```

Returns group standings (A through H).

#### Get Single Match

```
GET /v4/matches/{matchId}
```

### Match Object (JSON structure)

```json
{
  "id": 528437,
  "competition": { "id": 2000, "name": "FIFA World Cup" },
  "season": { "startDate": "2026-06-11", "endDate": "2026-07-19" },
  "utcDate": "2026-06-14T20:00:00Z",
  "status": "IN_PLAY",
  "matchday": 1,
  "stage": "GROUP_STAGE",
  "group": "GROUP_A",
  "homeTeam": {
    "id": 762,
    "name": "Brazil",
    "shortName": "Brazil",
    "tla": "BRA",
    "crest": "https://..."
  },
  "awayTeam": {
    "id": 764,
    "name": "Argentina",
    "shortName": "Argentina",
    "tla": "ARG",
    "crest": "https://..."
  },
  "score": {
    "winner": null,
    "duration": "REGULAR",
    "fullTime": { "home": null, "away": null },
    "halfTime": { "home": 1, "away": 0 }
  },
  "referees": [],
  "venue": "Estadio Azteca",
  "utcDate": "2026-06-14T20:00:00Z"
}
```

### Match Status Values

| Status      | Description                      |
| ----------- | -------------------------------- |
| `SCHEDULED` | Timed and ready to be played     |
| `TIMED`     | Kickoff time known               |
| `IN_PLAY`   | Match is in progress             |
| `PAUSED`    | Half-time or extra time break    |
| `FINISHED`  | Match has finished               |
| `SUSPENDED` | Match suspended                  |
| `POSTPONED` | Match postponed to a future date |
| `CANCELLED` | Match cancelled                  |
| `AWARDED`   | Match decided by authorities     |

### Standings Object

```json
{
  "competition": { "id": 2000, "name": "FIFA World Cup" },
  "season": { "id": 1564, "startDate": "2026-06-11" },
  "standings": [
    {
      "stage": "GROUP_STAGE",
      "type": "TOTAL",
      "group": "GROUP_A",
      "table": [
        {
          "position": 1,
          "team": { "id": 762, "name": "Brazil", "tla": "BRA" },
          "playedGames": 3,
          "won": 2,
          "draw": 1,
          "lost": 0,
          "points": 7,
          "goalsFor": 6,
          "goalsAgainst": 1,
          "goalDifference": 5
        }
      ]
    }
  ]
}
```

### Rate Limiting

- Free tier: 10 requests per minute.
- Response header `X-Ratelimit-Remaining` shows remaining requests.
- If exceeded: HTTP 429 Too Many Requests.
- Strategy: Queue requests, respect rate limits, cache responses.

---

## Secondary: TheSportsDB (backup/reference)

### Free Tier

- 30 requests/minute
- Free API key: `123`

### Endpoints

```
# Matches by date
GET /api/v1/json/123/eventsday.php?d=2026-06-14&s=Soccer

# Next events for a league
GET /api/v1/json/123/eventsnextleague.php?id=4614

# Previous events for a league
GET /api/v1/json/123/eventspastleague.php?id=4614
```

### Limitations

- Free tier limited search (only "Arsenal" for team search).
- Live scores require premium ($9/mo).
- Less reliable for real-time match data.

### Verdict

Not suitable as primary source. Could be used for team metadata (names, logos)
but football-data.org is better for live scores and standings.

---

## FIFA API (unofficial)

### Overview

- Used by FIFA.com website
- Base: `https://api.fifa.com/api/v3/`
- Not officially documented
- May change without notice

### Endpoints (discovered from FIFA.com)

```
# Team flags
GET /api/v3/picture/flags-sq-1/{TEAM_CODE}

# Match details
GET /api/v3/match/{competitionId}/{seasonId}/{matchId}
```

### Verdict

Too fragile for production use. Only useful for flag images.

---

## Polling Strategy Summary

```
┌─────────────────────────────────────────────────────┐
│                  PollController                      │
│                                                      │
│  States:                                             │
│  ┌──────┐    midnight    ┌──────────┐               │
│  │ IDLE ├───────────────►│ FETCHING │               │
│  └──┬───┘                └────┬─────┘               │
│     │                         │                      │
│     │ matches found           │ data received        │
│     │                         ▼                      │
│     │                    ┌──────────┐               │
│     │                    │ SCHEDULED │               │
│     │                    └────┬─────┘               │
│     │                         │                      │
│     │                    <5min to kickoff            │
│     │                         ▼                      │
│     │                    ┌──────────┐               │
│     │                    │  LIVE    │◄── poll 60s   │
│     │                    └────┬─────┘               │
│     │                         │                      │
│     │                    match finished              │
│     │                         ▼                      │
│     │                    ┌──────────┐               │
│     └────────────────────┤  IDLE    │               │
│                          └──────────┘               │
└─────────────────────────────────────────────────────┘
```

### Decision Tree

1. App launches → fetch today's matches
2. No matches today → set midnight timer → IDLE
3. Matches found → determine state (scheduled/live/finished)
4. Scheduled → timer to 5 min before kickoff → start polling
5. Live → poll every N seconds (default 60s, configurable)
6. Match finished → check for next match today → if none → IDLE
7. Midnight timer fires → fetch tomorrow's matches → repeat

### Error Handling

- Network error → retry in 60s (don't spam)
- API rate limit (429) → back off for 60s
- Invalid response → log error, use cached data
- No cached data → show "⚽ WC" in menu bar

---

## API Key Management

The football-data.org API key is stored in the app binary (hardcoded for v1).
This is acceptable because:

- Free tier is generous (10 req/min)
- The key doesn't grant access to sensitive data
- For production, we'd move to a proxy server

For v1, the key will be hardcoded in `FetchService.swift`.
