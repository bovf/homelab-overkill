---
name: qbit-list
description: List active qBittorrent torrents with name, state, progress %, category, download speed, and ETA. Read-only. Authenticates with the WebUI session cookie.
version: 0.1.0
author: dobry-ops
license: MIT
metadata:
  hermes:
    tags: [media, qbittorrent, downloads]
    category: media-ordering
    related_skills: [arr-search, nzbget-list]
---

# qbit-list

Read-only view of qBittorrent's current torrent list.

## When to use

User asks about torrent download status — "what's downloading", "how's qbit
looking", "any seeds I should kill", etc.

## Env vars

- `$QBITTORRENT_URL`
- `$QBITTORRENT_USERNAME`
- `$QBITTORRENT_PASSWORD`

## How

qBittorrent's WebUI requires login → session cookie → API:

```bash
COOKIE=$(mktemp)
trap 'rm -f "$COOKIE"' EXIT

curl -sf -c "$COOKIE" \
  -d "username=$QBITTORRENT_USERNAME&password=$QBITTORRENT_PASSWORD" \
  "$QBITTORRENT_URL/api/v2/auth/login" > /dev/null

curl -sf -b "$COOKIE" \
  "$QBITTORRENT_URL/api/v2/torrents/info" \
  | jq 'map({name, state, progress, category, dlspeed, eta})'
```

## Output format for the user

```
[1] Some.Movie.2025.1080p.BluRay.x265-GROUP
    State: downloading  Progress: 47%
    Category: radarr    Speed: 6.2 MiB/s    ETA: 12m
```

## Rules

- READ-ONLY. No add / pause / delete / re-category from this skill.
- Reference env vars by NAME; never paste values into chat.
- The login cookie is short-lived; don't try to cache it across skill runs.
- If `/api/v2/auth/login` returns "Fails." or HTTP 403, creds are wrong —
  say so, don't retry.
