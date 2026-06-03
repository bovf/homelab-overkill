---
name: nzbget-list
description: List the NZBGet download queue (active groups) and recent history (last 10 entries) via the JSON-RPC API with HTTP Basic auth.
version: 0.1.0
author: dobry-ops
license: MIT
metadata:
  hermes:
    tags: [media, nzbget, usenet, downloads]
    category: media-ordering
    related_skills: [arr-search, qbit-list]
---

# nzbget-list

Read-only view of NZBGet's current queue and recent history.

## When to use

User asks about Usenet download status — "what's in nzbget", "anything
stalled on usenet", "is the new episode done downloading", etc.

## Env vars

- `$NZBGET_URL`
- `$NZBGET_USERNAME` (the hale restricted user — add/list/monitor only)
- `$NZBGET_PASSWORD`

## How

NZBGet uses HTTP Basic auth on a single JSON-RPC endpoint.

Active queue (current downloads):

```bash
curl -sf -u "$NZBGET_USERNAME:$NZBGET_PASSWORD" \
  -H 'Content-Type: application/json' \
  -d '{"method":"listgroups","params":[0]}' \
  "$NZBGET_URL/jsonrpc" \
  | jq '.result | map({NZBName, Status, RemainingSizeMB, Category})'
```

Recent history (completed / failed / parked):

```bash
curl -sf -u "$NZBGET_USERNAME:$NZBGET_PASSWORD" \
  -H 'Content-Type: application/json' \
  -d '{"method":"history","params":[false]}' \
  "$NZBGET_URL/jsonrpc" \
  | jq '.result[0:10] | map({Name, Status, Category, DestDir})'
```

## Output format for the user

```
Queue:
[1] some.show.s01e02.1080p.WEB-DL.x265
    Status: DOWNLOADING  Remaining: 412 MB  Category: sonarr

History (last 10):
[1] some.movie.2024.1080p.BluRay.x265  ✓ SUCCESS/HEALTH  movies
```

## Rules

- READ-ONLY for this skill (the hale user is anyway restricted to
  add+list+monitor by NZBGet's role — no config-changing methods would
  succeed if you tried).
- Reference env vars by NAME; never paste values into chat.
- If you get HTTP 401, password is wrong — say so, don't retry.
