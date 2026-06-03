---
name: arr-library
description: List current library entries in radarr/sonarr/sportarr — title, year, monitored, hasFile, size on disk, quality profile. Read-only. Filterable.
version: 0.1.0
author: dobry-ops
license: MIT
metadata:
  hermes:
    tags: [media, library, radarr, sonarr, sportarr]
    category: media-ordering
    related_skills: [arr-search, arr-releases]
---

# arr-library

Read-only inventory of what's already in a *arr app's library.

## When to use

User asks "what's in radarr", "do I have <title>", "what movies are
missing files", "show me my sonarr series", etc. Also useful after
`arr-search` to check whether a match is already in the library.

## Env vars

- `$RADARR_URL` / `$RADARR_API_KEY`
- `$SONARR_URL` / `$SONARR_API_KEY`
- `$SPORTARR_URL` / `$SPORTARR_API_KEY`

## How

Radarr (movies):

```bash
curl -fsS -H "X-Api-Key: $RADARR_API_KEY" \
  "$RADARR_URL/api/v3/movie" \
  | jq 'map({
      title, year, tmdbId,
      monitored,
      hasFile,
      sizeOnDisk,
      qualityProfileId
    })'
```

Sonarr / sportarr (series):

```bash
curl -fsS -H "X-Api-Key: $SONARR_API_KEY" \
  "$SONARR_URL/api/v3/series" \
  | jq 'map({
      title, year, tvdbId,
      monitored,
      seasonCount: (.seasons | length),
      episodeCount,
      episodeFileCount,
      sizeOnDisk,
      qualityProfileId
    })'
```

## Filters

Common one-liners (compose into the jq pipeline):

- Missing files only: `map(select(.hasFile == false or .episodeFileCount == 0))`
- By title substring: `map(select(.title | test("hunger"; "i")))`
- Largest first: `sort_by(-.sizeOnDisk)`
- Unmonitored: `map(select(.monitored == false))`

## Output format for the user

```
[1] The Hunger Games (2012)         monitored ✓  hasFile ✓  3.2 GiB
[2] Severance (2022)                monitored ✓  3 / 19 ep  8.1 GiB
[3] Some Old Movie (1999)           monitored ✗  hasFile ✗
```

## Rules

- READ-ONLY. Never PUT/POST/DELETE from this skill.
- For large libraries (>50 entries), filter or paginate — don't dump all of
  it into the chat.
- Reference env vars by NAME.
