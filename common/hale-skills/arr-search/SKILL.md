---
name: arr-search
description: Search radarr/sonarr/sportarr by title via /api/v3/{movie|series}/lookup using the X-Api-Key header. Read-only. Returns up to 5 matches with poster URLs.
version: 0.1.0
author: dobry-ops
license: MIT
metadata:
  hermes:
    tags: [media, search, radarr, sonarr, sportarr]
    category: media-ordering
    related_skills: [arr-library, qbit-list, nzbget-list]
---

# arr-search

Read-only title lookup against any *arr app in the homelab.

## When to use

User asks to search/find/look-up a title on radarr (movies), sonarr (series),
or sportarr (sports series). Examples:
- "search radarr for The Hunger Games"
- "find Severance on sonarr"
- "look up the F1 season on sportarr"

## Env vars (already in your environment)

- `$RADARR_URL` / `$RADARR_API_KEY`
- `$SONARR_URL` / `$SONARR_API_KEY`
- `$SPORTARR_URL` / `$SPORTARR_API_KEY`

## How

Movies (radarr):

```bash
curl -fsS -H "X-Api-Key: $RADARR_API_KEY" \
  --get --data-urlencode "term=<query>" \
  "$RADARR_URL/api/v3/movie/lookup" \
  | jq '.[0:5] | map({title, year, tmdbId, imdbId, remotePoster})'
```

Series (sonarr / sportarr — both use the same series shape):

```bash
curl -fsS -H "X-Api-Key: $SONARR_API_KEY" \
  --get --data-urlencode "term=<query>" \
  "$SONARR_URL/api/v3/series/lookup" \
  | jq '.[0:5] | map({title, year, tvdbId, imdbId, remotePoster})'
```

## Output format for the user

Single markdown table. Cap at 10 rows unless the user asks for more.
Posters, TMDb, and IMDb columns are LINKS (markdown link syntax), not
inline images and not raw URLs.

```
| Pick | Title | Year | Runtime | TMDb | IMDb | In Radarr | Poster |
|---:|---|---:|---:|---:|---|---:|---|
| 1 | **Mulan** | 1998 | 88m | [10674](https://www.themoviedb.org/movie/10674) | [tt0120762](https://www.imdb.com/title/tt0120762) | no | [poster](https://image.tmdb.org/t/p/original/...jpg) |
```

Link templates:

- TMDb movie: `https://www.themoviedb.org/movie/<tmdbId>`
- TMDb series: `https://www.themoviedb.org/tv/<tvdbId-or-tmdbId>`
- IMDb (when `imdbId` is present): `https://www.imdb.com/title/<imdbId>`
- Poster: the `remotePoster` URL from the API response, exactly as-is

If a field is missing in the API response (no `imdbId`, no `remotePoster`),
print `n/a` for that cell — don't emit a broken link.

After the table, one short paragraph with your "Saxton guess" (the 1–2 most
likely picks) and the next-step prompt: `Say "inspect N" to see release
candidates.`

## Rules

- READ-ONLY. Never POST from this skill.
- Reference env vars by NAME (`$RADARR_API_KEY`). Never paste values into chat.
- Cap results at 5. If user wants more, raise the slice.
- If the API returns 401, the key is wrong or the URL points at the wrong service — say so, don't retry blindly.
