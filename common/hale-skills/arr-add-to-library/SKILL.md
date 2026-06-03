---
name: arr-add-to-library
description: Add a movie/series to radarr/sonarr/sportarr's library with chosen quality profile and root folder. DESTRUCTIVE — creates a permanent library entry, optionally triggers an automatic indexer search and grab. MUST ONLY be invoked after explicit user confirmation ("add 1", "yes add it", "confirm add").
version: 0.1.0
author: dobry-ops
license: MIT
metadata:
  hermes:
    tags: [media, library, add, destructive, radarr, sonarr, sportarr, confirmation-gated]
    category: media-ordering
    related_skills: [arr-search, arr-library, arr-releases, arr-grab]
    config:
      destructive: true
---

# arr-add-to-library

⚠️ **DESTRUCTIVE** — creates a permanent library entry in radarr/sonarr/sportarr.
Optionally triggers an automatic indexer search and grab of the best release.

## CONFIRMATION GATE — THE FIRST RULE

You **MUST NOT** invoke this skill until the user has explicitly confirmed
with unambiguous add language:

- `add 1`, `add #2`, `add option 3`
- `yes add it`, `confirm add`
- `go ahead`, `do it`

You **MUST NOT** invoke this skill if the user has only said:

- "show me" → use `arr-search`
- "what's available" → use `arr-search`
- "looks interesting" → AMBIGUOUS, ask for explicit confirmation

If the user wants the bot to also start downloading immediately, they must
also say `search on add` or `auto-grab` — otherwise `searchForMovie`/
`searchForMissingEpisodes` defaults to `false` (add only, user picks
releases manually via `arr-releases` + `arr-grab`).

## When to use (the loop)

1. User picks a title from `arr-search` output.
2. You restate the planned add: title + chosen quality profile + chosen
   root folder + monitored=true + search-on-add yes/no.
3. User replies with explicit add confirmation.
4. **Only now**: invoke this skill.

## Env vars

- `$RADARR_URL` / `$RADARR_API_KEY`
- `$SONARR_URL` / `$SONARR_API_KEY`
- `$SPORTARR_URL` / `$SPORTARR_API_KEY`

## How

### Step 1 — discover quality profile and root folder

```bash
# Quality profiles available in radarr
curl -fsS -H "X-Api-Key: $RADARR_API_KEY" \
  "$RADARR_URL/api/v3/qualityprofile" \
  | jq 'map({id, name})'

# Root folders configured
curl -fsS -H "X-Api-Key: $RADARR_API_KEY" \
  "$RADARR_URL/api/v3/rootfolder" \
  | jq 'map({id, path, freeSpace})'
```

Default behaviour if user didn't specify: pick the first quality profile
and the first root folder with adequate free space. Surface both choices
in the confirmation message — never silently add with surprise defaults.

### Step 2 — POST the add

Radarr (movies):

```bash
curl -fsS -X POST -H "X-Api-Key: $RADARR_API_KEY" \
  -H 'Content-Type: application/json' \
  -d "$(jq -n \
    --arg title "$TITLE" \
    --argjson tmdbId "$TMDB_ID" \
    --argjson year "$YEAR" \
    --argjson qpId "$QUALITY_PROFILE_ID" \
    --arg root "$ROOT_FOLDER_PATH" \
    --argjson search "$SEARCH_ON_ADD" \
    '{
      title: $title,
      tmdbId: $tmdbId,
      year: $year,
      qualityProfileId: $qpId,
      rootFolderPath: $root,
      monitored: true,
      minimumAvailability: "released",
      addOptions: { searchForMovie: $search }
    }')" \
  "$RADARR_URL/api/v3/movie"
```

Sonarr / sportarr (series):

```bash
curl -fsS -X POST -H "X-Api-Key: $SONARR_API_KEY" \
  -H 'Content-Type: application/json' \
  -d "$(jq -n \
    --arg title "$TITLE" \
    --argjson tvdbId "$TVDB_ID" \
    --argjson qpId "$QUALITY_PROFILE_ID" \
    --arg root "$ROOT_FOLDER_PATH" \
    --argjson search "$SEARCH_ON_ADD" \
    '{
      title: $title,
      tvdbId: $tvdbId,
      qualityProfileId: $qpId,
      rootFolderPath: $root,
      monitored: true,
      seasonFolder: true,
      seriesType: "standard",
      addOptions: {
        searchForMissingEpisodes: $search,
        searchForCutoffUnmetEpisodes: false,
        monitor: "all"
      }
    }')" \
  "$SONARR_URL/api/v3/series"
```

A 201 response means the entry was created. The body contains the new
record with an `id`. If `searchForMovie`/`searchForMissingEpisodes` was
true, the *arr app has also kicked off an indexer search; releases will
be evaluated and the best one auto-grabbed per the quality profile.

If you get 400 with "MovieExistsValidator" or similar, the title is
already in the library — say so plainly, don't retry.

## Output format for the user

```
✓ Added: Lilo & Stitch (2002)
  App: radarr
  Quality profile: HD-1080p
  Root folder: /movies (412 GiB free)
  Monitored: yes
  Search on add: no — pick a release via `releases 1`
```

If `search on add: yes`:

```
✓ Added: Lilo & Stitch (2002), search triggered
  App: radarr
  Quality profile: HD-1080p
  Root folder: /movies (412 GiB free)
  Monitored: yes
  Search on add: yes — radarr will auto-grab the best release per profile
  Track progress: `qbit-list` / `nzbget-list` in ~30s
```

## Rules

- **No confirmation, no add.** First rule.
- Show the chosen quality profile + root folder in the confirmation prompt
  BEFORE adding. Never silently pick defaults.
- Default `searchForMovie`/`searchForMissingEpisodes` to `false`. User
  explicitly opts in to auto-grab with "search on add".
- One add per invocation. Multiple titles = multiple confirmations.
- Check the arr-search response for `existing`/`id` fields first; if the
  movie is already in the library, refuse and tell the user.
- This skill **does not** trigger a release grab on its own (unless
  search-on-add is requested). After add, the loop continues:
  `arr-releases` → user picks → `arr-grab`.
- Reference env vars by NAME; never paste values into chat.
