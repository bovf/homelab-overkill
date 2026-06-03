---
name: media-status
description: One-glance health overview of every media service (radarr, sonarr, sportarr, prowlarr, bazarr, qbittorrent, nzbget). Hits each service's status/health endpoint and reports version, reachability, and any active health warnings.
version: 0.1.0
author: dobry-ops
license: MIT
metadata:
  hermes:
    tags: [media, status, health, diagnostics]
    category: media-ordering
    related_skills: [arr-search, qbit-list, nzbget-list]
---

# media-status

Read-only health check across the whole media stack. Use this first whenever
the user reports "something's broken" with media — it tells you which service
is the prime suspect.

## When to use

- "is everything up", "media status", "anything broken with my media"
- As the first probe in a diagnosis flow before drilling into a single app
- Before suggesting a grab — if the destination download client is down, say so

## Env vars

All of:
`$RADARR_URL`, `$RADARR_API_KEY`,
`$SONARR_URL`, `$SONARR_API_KEY`,
`$SPORTARR_URL`, `$SPORTARR_API_KEY`,
`$PROWLARR_URL`, `$PROWLARR_API_KEY`,
`$BAZARR_URL`, `$BAZARR_API_KEY`,
`$QBITTORRENT_URL`, `$QBITTORRENT_USERNAME`, `$QBITTORRENT_PASSWORD`,
`$NZBGET_URL`, `$NZBGET_USERNAME`, `$NZBGET_PASSWORD`.

## How

For each *arr app — version + health:

```bash
for app in radarr sonarr sportarr prowlarr bazarr; do
  URL_VAR="$(echo $app | tr a-z A-Z)_URL"
  KEY_VAR="$(echo $app | tr a-z A-Z)_API_KEY"
  URL="${!URL_VAR}"; KEY="${!KEY_VAR}"

  echo "=== $app ==="
  curl -fsS --max-time 3 -H "X-Api-Key: $KEY" \
    "$URL/api/v3/system/status" \
    | jq '{version, branch, runtimeVersion, isProduction}' 2>&1 \
    || echo "  ✗ unreachable"

  curl -fsS --max-time 3 -H "X-Api-Key: $KEY" \
    "$URL/api/v3/health" \
    | jq 'map({source, type, message})' 2>&1 \
    || echo "  ✗ health endpoint unreachable"
done
```

qBittorrent — version + torrent counts by state:

```bash
COOKIE=$(mktemp); trap 'rm -f "$COOKIE"' EXIT
curl -sf -c "$COOKIE" --max-time 3 \
  -d "username=$QBITTORRENT_USERNAME&password=$QBITTORRENT_PASSWORD" \
  "$QBITTORRENT_URL/api/v2/auth/login" > /dev/null

curl -sf -b "$COOKIE" --max-time 3 "$QBITTORRENT_URL/api/v2/app/version"
curl -sf -b "$COOKIE" --max-time 3 "$QBITTORRENT_URL/api/v2/torrents/info" \
  | jq 'group_by(.state) | map({state: .[0].state, count: length})'
```

NZBGet — status method:

```bash
curl -sf --max-time 3 -u "$NZBGET_USERNAME:$NZBGET_PASSWORD" \
  -H 'Content-Type: application/json' \
  -d '{"method":"status","params":[]}' \
  "$NZBGET_URL/jsonrpc" \
  | jq '.result | {ServerPaused, DownloadPaused, RemainingSizeMB, DownloadRate, FreeDiskSpaceMB, ServerStandBy}'
```

## Output format for the user

```
=== Media stack ===
radarr      ✓ v6.1.1     no health issues
sonarr      ✓ v4.0.15.2  1 warning: indexer "X" is unreachable
sportarr    ✓ v4.0.15.2  no health issues
prowlarr    ✓ v1.42.0    no health issues
bazarr      ✗ unreachable (timeout)
qbittorrent ✓ v5.0.5     34 downloading, 412 seeding
nzbget      ✓            2 active, 412 MB queued, 28 GiB free disk
```

Lead with the unhealthy ones if any. If everything's green, say so plainly
in one line.

## Rules

- READ-ONLY across the board.
- Use `--max-time 3` on every request so a single dead service doesn't hang
  the whole report.
- Treat any non-2xx or timeout as "✗ unreachable" — don't try to fix anything
  from this skill; that's the user's call.
- Reference env vars by NAME; never paste values into chat.
