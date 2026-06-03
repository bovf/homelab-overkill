---
name: arr-search-mobile
description: Mobile-friendly variant of arr-search. Same radarr/sonarr/sportarr lookup, but output is a compact vertical list (~2 lines per pick, no wide table) that fits inside a phone message bubble in Element X mobile / FluffyChat / etc.
version: 0.1.0
author: dobry-ops
license: MIT
metadata:
  hermes:
    tags: [media, search, radarr, sonarr, sportarr, mobile]
    category: media-ordering
    related_skills: [arr-search, arr-library, arr-releases]
---

# arr-search-mobile

Compact title lookup output sized for phone-bubble width.

## When to use

Same triggers as `arr-search` (lookup a title in radarr/sonarr/sportarr),
BUT prefer this variant when ANY of:

- The user explicitly says "phone", "mobile", "on my phone", "Element X",
  "compact", "smaller"
- The user complains the previous table was unreadable, crushed, too wide
- The user has previously asked for the mobile variant in this room

If the user hasn't signalled mobile and you don't know their context, use
the regular `arr-search` for a full table. Don't second-guess.

## Env vars

Identical to `arr-search`:

- `$RADARR_URL` / `$RADARR_API_KEY`
- `$SONARR_URL` / `$SONARR_API_KEY`
- `$SPORTARR_URL` / `$SPORTARR_API_KEY`

## How

Same as `arr-search`. Movies via `/api/v3/movie/lookup`, series via
`/api/v3/series/lookup`. See that skill for the curl examples.

## Output format — compact vertical list

Two lines per pick. Cap at 5 (phone screens fill fast). Bold the pick
number and title; details and links go on the second line, separated by
`·` for scannability.

```
**[1] Mulan** (1998 · 88m · not in radarr)
[TMDb](https://www.themoviedb.org/movie/10674) · [IMDb](https://www.imdb.com/title/tt0120762) · [poster](https://image.tmdb.org/t/p/w342/...jpg)

**[2] Mulan** (2020 · 115m · not in radarr)
[TMDb](https://www.themoviedb.org/movie/337401) · [IMDb](https://www.imdb.com/title/tt4566758) · [poster](https://image.tmdb.org/t/p/w342/...jpg)

**[3] Mulan II** (2004 · 79m · not in radarr)
[TMDb](https://www.themoviedb.org/movie/12242) · [IMDb](https://www.imdb.com/title/tt0279967) · [poster](https://image.tmdb.org/t/p/w342/...jpg)
```

Notes on rendering:

- **No tables.** Markdown tables crush on phone-bubble widths; that's the
  whole reason this skill exists.
- Use `·` (middle dot) between fields — narrower than ` | ` and scans better.
- Use the `/t/p/w342/...` TMDB poster size (≈342px wide thumbnail) so the
  link target loads fast on cellular if the user taps through.
- If a field is missing, just omit it from the second-line list — don't
  print `n/a · n/a · n/a`. Skip empties for compactness.
- Use markdown emphasis (`**bold**`, `*italic*`) sparingly — Element X
  renders both fine.

## Close with a short hint

After the picks, one short line:

```
Reply `inspect N` and I'll check release candidates.
```

No long paragraphs. No big "Saxton guess" speech. Mobile users want signal,
not banter — keep your usual character but tight.

## Rules

- READ-ONLY (inherits from arr-search).
- Cap at 5 picks. If user asks for more, raise the slice but warn it'll
  scroll a lot on phone.
- Reference env vars by NAME.
