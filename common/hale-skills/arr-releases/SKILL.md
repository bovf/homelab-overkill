---
name: arr-releases
description: List ranked release candidates for a movie or episode/season in radarr/sonarr/sportarr. Applies storage-conscious ranking (Usenet > torrent, 1080p WEB-DL/BluRay preferred, x265 preferred, REMUX/4K demoted). Read-only — does NOT grab. Pair with arr-grab for confirmation-gated grabbing.
version: 0.1.0
author: dobry-ops
license: MIT
metadata:
  hermes:
    tags: [media, releases, ranking, radarr, sonarr, sportarr]
    category: media-ordering
    related_skills: [arr-search, arr-library, arr-grab]
---

# arr-releases

Fetch candidate releases from a *arr app's indexers, apply the storage-
conscious ranking policy, return the top N with reasons.

## When to use

After `arr-search` or `arr-library` resolves a specific title to its arr ID,
and the user wants to see what's available to grab. Examples:
- "what releases are there for The Hunger Games"
- "show me sonarr releases for Severance S01E03"
- "rank what's available for the new F1 race on sportarr"

## Env vars

- `$RADARR_URL` / `$RADARR_API_KEY`
- `$SONARR_URL` / `$SONARR_API_KEY`
- `$SPORTARR_URL` / `$SPORTARR_API_KEY`

## How

Radarr (by movieId from arr-search/arr-library):

```bash
curl -fsS -H "X-Api-Key: $RADARR_API_KEY" \
  "$RADARR_URL/api/v3/release?movieId=$MOVIE_ID"
```

Sonarr / sportarr (by episodeId or seriesId+seasonNumber):

```bash
curl -fsS -H "X-Api-Key: $SONARR_API_KEY" \
  "$SONARR_URL/api/v3/release?episodeId=$EPISODE_ID"
# or for a whole season:
curl -fsS -H "X-Api-Key: $SONARR_API_KEY" \
  "$SONARR_URL/api/v3/release?seriesId=$SERIES_ID&seasonNumber=$SEASON"
```

## Ranking pipeline (storage-conscious default)

Pipe the response through this jq to score, sort, and slim:

```jq
map(
  . + {
    _score: (
      (if .protocol == "usenet" then 30 else 0 end)
      + (if (.title // "" | test("1080p"))             then 20 else 0 end)
      + (if (.title // "" | test("WEB-DL|BluRay"; "i")) then 10 else 0 end)
      + (if (.title // "" | test("x265|HEVC"; "i"))     then 8  else 0 end)
      + (.customFormatScore // 0)
      - (if (.title // "" | test("REMUX"; "i"))        then 25 else 0 end)
      - (if (.title // "" | test("2160p|4K"; "i"))     then 30 else 0 end)
      - (if (.title // "" | test("CAM|HDCAM|TS\\b"; "i")) then 100 else 0 end)
      - (if .rejected then 1000 else 0 end)
    )
  }
) | sort_by(-._score) | .[0:10] | map({
  title,
  protocol,
  indexer,
  quality: .quality.quality.name,
  sizeMB: ((.size // 0) / 1048576 | floor),
  seeders,
  customFormatScore,
  rejected,
  rejections,
  guid,
  indexerId,
  _score
})
```

## Output format for the user

```
[1] The.Hunger.Games.2012.1080p.BluRay.x265-GROUP
    Protocol: Usenet/NZB     Indexer: NZBPlanet
    Quality:  1080p BluRay   Size:    3.2 GiB
    Score:    63             Rejected: no
    Why:      Usenet (+30), 1080p (+20), BluRay (+10), x265 (+8) — best storage/quality ratio

[2] The.Hunger.Games.2012.1080p.WEB-DL.x265-GROUP
    Protocol: Torrent        Indexer: 1337x
    Quality:  1080p WEB-DL   Size:    2.8 GiB
    Score:    38             Seeders: 142
    Why:      1080p (+20), WEB-DL (+10), x265 (+8); torrent (no protocol bonus)
```

Always show the `_score` decomposition and rejection reasons. Surface why the
top pick won, not just the winner.

## Mode overrides the user may ask for

- "go 4k" / "give me REMUX" → reapply with the 4K/REMUX penalties removed.
- "torrent only" / "no usenet" → filter `protocol` first.
- "highest seeder count" → re-sort by `.seeders` after filtering.

## Rules

- READ-ONLY. Returning the `guid` + `indexerId` is fine; it's required for
  the user to confirm a grab via `arr-grab`. The list itself triggers nothing.
- Cap output at 10 unless asked for more.
- Always include rejection reasons if any release has them — the user needs
  to see why "obvious-looking" candidates were rejected.
- Reference env vars by NAME; never paste values.
