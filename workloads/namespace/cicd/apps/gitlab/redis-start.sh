#!/bin/sh
set -eu

# A fresh Redis would silently discard sessions and queued jobs during cutover.
if [ ! -s /data/.homelab-redis-restored ] || [ ! -s /data/appendonlydir/appendonly.aof.manifest ]; then
  echo "Redis restore is not confirmed. Follow gitlab/UPGRADE.md before starting this workload." >&2
  exit 1
fi

: "${REDISCLI_AUTH:?The existing GitLab Redis credential is required}"
# Keep credentials out of argv/logs; reject control characters before writing config.
if [ "$(printf '%s' "$REDISCLI_AUTH" | LC_ALL=C tr -d '[:cntrl:]')" != "$REDISCLI_AUTH" ]; then
  echo "Redis password must not contain control characters." >&2
  exit 1
fi
escaped=$(printf '%s' "$REDISCLI_AUTH" | sed 's/[\\"]/\\&/g')
umask 077
printf 'requirepass "%s"\n' "$escaped" > /tmp/redis-auth.conf

exec redis-server /tmp/redis-auth.conf \
  --bind 0.0.0.0 --protected-mode yes \
  --dir /data --appendonly yes --appendfsync everysec --save "" \
  --maxmemory-policy noeviction \
  --rename-command FLUSHDB "" --rename-command FLUSHALL ""
