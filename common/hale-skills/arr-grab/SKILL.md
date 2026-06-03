---
name: arr-grab
description: POST a chosen release to radarr/sonarr/sportarr to start the grab. DESTRUCTIVE — initiates a real download. MUST ONLY be invoked after explicit user confirmation language ("grab N", "yes grab it", "confirm"). Refuses on absence of confirmation context.
version: 0.1.0
author: dobry-ops
license: MIT
metadata:
  hermes:
    tags: [media, grab, destructive, radarr, sonarr, sportarr, confirmation-gated]
    category: media-ordering
    related_skills: [arr-search, arr-releases]
    config:
      destructive: true
---

# arr-grab

⚠️ **DESTRUCTIVE** — starts an actual download via the chosen download client.

## CONFIRMATION GATE — THE FIRST RULE

You **MUST NOT** invoke this skill until the user has explicitly confirmed
with unambiguous grab language. Acceptable confirmation phrases include:

- `grab 1`, `grab #2`, `grab option 3`
- `yes grab it`, `confirm grab`
- `go ahead`, `do it`, `pull the trigger`

You **MUST NOT** invoke this skill if the user has only said:

- "show me releases" → use `arr-releases`
- "rank them" → use `arr-releases`
- "what's available" → use `arr-releases`
- "looks good" / "interesting" / "ok" → AMBIGUOUS. Ask for explicit confirmation.

If you are uncertain whether confirmation has been given, **ASK**:

> "I can grab option [N]: `<release title>`. This will send a download
>  request to <app> on <indexer>. Confirm: 'grab <N>' to proceed."

Then wait for an unambiguous reply. Do not pre-emptively call this skill
"because the user probably meant yes".

## When to use (the loop)

1. User picks a release from `arr-releases` output.
2. You restate the grab plainly + ask for explicit confirmation.
3. User replies with confirmation language.
4. **Only now**: invoke this skill.

## Env vars

- `$RADARR_URL` / `$RADARR_API_KEY`
- `$SONARR_URL` / `$SONARR_API_KEY`
- `$SPORTARR_URL` / `$SPORTARR_API_KEY`

## How

The body is the `guid` + `indexerId` from the chosen `arr-releases` entry.

Radarr:

```bash
curl -fsS -X POST -H "X-Api-Key: $RADARR_API_KEY" \
  -H 'Content-Type: application/json' \
  -d "{\"guid\":\"$GUID\",\"indexerId\":$INDEXER_ID}" \
  "$RADARR_URL/api/v3/release"
```

Sonarr / sportarr — identical shape, different host:

```bash
curl -fsS -X POST -H "X-Api-Key: $SONARR_API_KEY" \
  -H 'Content-Type: application/json' \
  -d "{\"guid\":\"$GUID\",\"indexerId\":$INDEXER_ID}" \
  "$SONARR_URL/api/v3/release"
```

A 2xx response means the *arr app accepted the release and pushed it to the
download client (qBittorrent / NZBGet) — it does NOT mean the download is
complete. Use `qbit-list` / `nzbget-list` to check progress.

## Output format for the user

```
✓ Grabbed: The.Hunger.Games.2012.1080p.BluRay.x265-GROUP
  Sent to: radarr → nzbget (Usenet)
  Track progress: `nzbget-list` or `qbit-list`
```

If the API returns a non-2xx, report it verbatim — don't retry:

```
✗ Grab rejected by radarr (HTTP 400):
  <response body>
```

## Rules

- **No confirmation, no grab.** This is the most important rule.
- One grab per invocation. If the user wants to grab multiple releases,
  invoke this skill once per release with a fresh confirmation each time.
- Don't add the title to the library from here — that's a separate flow
  (radarr's `POST /api/v3/movie`, not yet shipped as a skill).
- Reference env vars by NAME; never paste values into chat.
- If the user changes their mind mid-flow ("wait, actually grab #2 instead"),
  treat that as a new confirmation for #2 — not as cover to grab both.
