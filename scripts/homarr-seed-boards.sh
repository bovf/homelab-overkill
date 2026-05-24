#!/usr/bin/env bash
#
# Seed Homarr's SQLite DB with Media / Infrastructure / Read boards.
#
# Idempotent on apps (INSERT OR IGNORE). Boards have a UNIQUE name index,
# so re-running fails fast on already-created boards — by design, so we
# don't silently clobber a board you've started editing.
#
# Run from your Mac:  bash scripts/homarr-seed-boards.sh
#
# Adds widgets is OUT OF SCOPE — Homarr widget option-JSON varies per
# widget kind and is best added through the UI (1–2 clicks per widget).
# The skeleton, sections, and all app/bookmark tiles are seeded here.

set -euo pipefail

USER_ID='se3k1t6k1w9c60tb95rqgz2l'

# Existing app IDs (created when you set up integrations in Homarr UI).
JELLYFIN_ID='oscfgxudb6fdwkmkgpgwcpt1'
JELLYSEERR_ID='k15xuj3mgl22i950j5jc0cde'
SONARR_ID='u6dij462e6mgon7s3afi6gf6'
RADARR_ID='etva9lkq4xrvj7nsrhgpebwr'
PROWLARR_ID='vll71l0ixgesqtjgvouyguv3'
QBITTORRENT_ID='f7cz5jsw2kt37f302g6cz0mn'
NZBGET_ID='abd1s57n814byv5q5tkfre3g'
PIHOLE_ID='ie81ptu58gs8zu4sdyoqz3kn'

# New 24-char hex IDs for everything else — generated once per run.
gen() { openssl rand -hex 12; }

# New bookmark/app IDs.
BAZARR_ID=$(gen)
GRAFANA_ID=$(gen)
PROMETHEUS_ID=$(gen)
ALERTMANAGER_ID=$(gen)
TRAEFIK_ID=$(gen)
GITLAB_ID=$(gen)
REGISTRY_ID=$(gen)
ARGOCD_ID=$(gen)
MINIO_ID=$(gen)
MINIO_CONSOLE_ID=$(gen)
PGADMIN_ID=$(gen)
PANGOLIN_ID=$(gen)
ELEMENT_ID=$(gen)
SYNAPSE_ADMIN_ID=$(gen)
EZBOOKKEEPING_ID=$(gen)
SPORTARR_ID=$(gen)
CALENDAR_ID=$(gen)
GMAIL_ID=$(gen)
DRIVE_ID=$(gen)
PHOTOS_ID=$(gen)

# Board IDs.
MEDIA_BOARD_ID=$(gen)
INFRA_BOARD_ID=$(gen)
READ_BOARD_ID=$(gen)

# One desktop layout per board: column_count=12, breakpoint=0.
MEDIA_LAYOUT_ID=$(gen)
INFRA_LAYOUT_ID=$(gen)
READ_LAYOUT_ID=$(gen)

# Media board sections.
MEDIA_S_WATCHING_ID=$(gen)
MEDIA_S_LIBRARY_ID=$(gen)
MEDIA_S_DLOAD_ID=$(gen)

# Infrastructure board sections.
INFRA_S_OBS_ID=$(gen)
INFRA_S_SCM_ID=$(gen)
INFRA_S_STORAGE_ID=$(gen)
INFRA_S_NET_ID=$(gen)
INFRA_S_MATRIX_ID=$(gen)
INFRA_S_APPS_ID=$(gen)

# Read board sections.
READ_S_NEWS_ID=$(gen)
READ_S_PERSONAL_ID=$(gen)

# Helper: emit an INSERT for item + item_layout for an app tile.
# args: item_id app_id section_id layout_id x y w h
app_item() {
  local IID=$(gen) AID=$2 SID=$3 LID=$4 X=$5 Y=$6 W=$7 H=$8
  cat <<EOF
INSERT INTO item (id, board_id, kind, options, advanced_options) VALUES
  ('$IID', '$1', 'app',
   '{"json":{"appId":"$AID"}}',
   '{"json":{"title":null,"customCssClasses":[],"borderColor":""}}');
INSERT INTO item_layout (item_id, section_id, layout_id, x_offset, y_offset, width, height) VALUES
  ('$IID', '$SID', '$LID', $X, $Y, $W, $H);
EOF
}

ICON="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons@master/svg"

SQL=$(cat <<EOF
BEGIN;

-- =========================================================================
-- NEW APPS (bookmarks). INSERT OR IGNORE on (id), but names are unique
-- by convention so duplicates won't sneak in even with new random IDs
-- across re-runs.
-- =========================================================================
INSERT OR IGNORE INTO app (id, name, description, icon_url, href, ping_url) VALUES
  ('$BAZARR_ID',         'Bazarr',           '', '$ICON/bazarr.svg',           'https://bazarr.dobryops.com',         'http://bazarr.media.svc.cluster.local:6767'),
  ('$GRAFANA_ID',        'Grafana',          '', '$ICON/grafana.svg',          'https://grafana.dobryops.com',        NULL),
  ('$PROMETHEUS_ID',     'Prometheus',       '', '$ICON/prometheus.svg',       'https://prometheus.dobryops.com',     NULL),
  ('$ALERTMANAGER_ID',   'Alertmanager',     '', '$ICON/prometheus.svg',       'https://alertmanager.dobryops.com',   NULL),
  ('$TRAEFIK_ID',        'Traefik',          '', '$ICON/traefik.svg',          'https://traefik.dobryops.com',        NULL),
  ('$GITLAB_ID',         'GitLab',           '', '$ICON/gitlab.svg',           'https://gitlab.dobryops.com',         NULL),
  ('$REGISTRY_ID',       'Container Registry','', '$ICON/docker.svg',          'https://registry.dobryops.com',       NULL),
  ('$ARGOCD_ID',         'ArgoCD',           '', '$ICON/argo-cd.svg',          'https://argocd.dobryops.com',         NULL),
  ('$MINIO_ID',          'MinIO',            '', '$ICON/minio.svg',            'https://minio.dobryops.com',          NULL),
  ('$MINIO_CONSOLE_ID',  'MinIO Console',    '', '$ICON/minio.svg',            'https://minio-console.dobryops.com',  NULL),
  ('$PGADMIN_ID',        'pgAdmin',          '', '$ICON/pgadmin.svg',          'https://pgadmin.dobryops.com',        NULL),
  ('$PANGOLIN_ID',       'Pangolin',         '', '$ICON/cloudflare-tunnel.svg','https://pangolin.dobryops.com',       NULL),
  ('$ELEMENT_ID',        'Element',          '', '$ICON/element.svg',          'https://element.dobryops.com',        NULL),
  ('$SYNAPSE_ADMIN_ID',  'Synapse-admin',    '', '$ICON/matrix.svg',           'https://synapse-admin.dobryops.com',  NULL),
  ('$EZBOOKKEEPING_ID',  'ezBookkeeping',    '', '$ICON/actual-budget.svg',    'https://ezbookkeeping.dobryops.com',  NULL),
  ('$SPORTARR_ID',       'Sportarr',         '', '$ICON/sonarr.svg',           'https://sportarr.dobryops.com',       NULL),
  ('$CALENDAR_ID',       'Google Calendar',  '', '$ICON/google-calendar.svg',  'https://calendar.google.com',         NULL),
  ('$GMAIL_ID',          'Gmail',            '', '$ICON/google-mail.svg',      'https://mail.google.com',             NULL),
  ('$DRIVE_ID',          'Google Drive',     '', '$ICON/google-drive.svg',     'https://drive.google.com',            NULL),
  ('$PHOTOS_ID',         'Google Photos',    '', '$ICON/google-photos.svg',    'https://photos.google.com',           NULL);

-- =========================================================================
-- BOARDS (Media, Infrastructure, Read)
-- =========================================================================
INSERT INTO board (id, name, is_public, creator_id, page_title, meta_title, primary_color, secondary_color, opacity, item_radius) VALUES
  ('$MEDIA_BOARD_ID', 'Media',          0, '$USER_ID', 'Media',          'Media — dobryops',          '#9775fa', '#5c7cfa', 100, 'lg'),
  ('$INFRA_BOARD_ID', 'Infrastructure', 0, '$USER_ID', 'Infrastructure', 'Infrastructure — dobryops', '#37b24d', '#0ca678', 100, 'lg'),
  ('$READ_BOARD_ID',  'Read',           0, '$USER_ID', 'Read',           'Read — dobryops',           '#f76707', '#e8590c', 100, 'lg');

INSERT INTO layout (id, name, board_id, column_count, breakpoint) VALUES
  ('$MEDIA_LAYOUT_ID', 'Base', '$MEDIA_BOARD_ID', 12, 0),
  ('$INFRA_LAYOUT_ID', 'Base', '$INFRA_BOARD_ID', 12, 0),
  ('$READ_LAYOUT_ID',  'Base', '$READ_BOARD_ID',  12, 0);

-- =========================================================================
-- MEDIA BOARD SECTIONS + ITEMS
-- =========================================================================
INSERT INTO section (id, board_id, kind, x_offset, y_offset, name, options) VALUES
  ('$MEDIA_S_WATCHING_ID', '$MEDIA_BOARD_ID', 'category', 0, 0, 'Watching',       '{"json": {}}'),
  ('$MEDIA_S_LIBRARY_ID',  '$MEDIA_BOARD_ID', 'category', 0, 1, 'Library (*arr)', '{"json": {}}'),
  ('$MEDIA_S_DLOAD_ID',    '$MEDIA_BOARD_ID', 'category', 0, 2, 'Downloaders',    '{"json": {}}');
$(app_item "$MEDIA_BOARD_ID" "$JELLYFIN_ID"    "$MEDIA_S_WATCHING_ID" "$MEDIA_LAYOUT_ID" 0 0 3 3)
$(app_item "$MEDIA_BOARD_ID" "$JELLYSEERR_ID"  "$MEDIA_S_WATCHING_ID" "$MEDIA_LAYOUT_ID" 3 0 3 3)
$(app_item "$MEDIA_BOARD_ID" "$SONARR_ID"      "$MEDIA_S_LIBRARY_ID"  "$MEDIA_LAYOUT_ID" 0 0 3 3)
$(app_item "$MEDIA_BOARD_ID" "$RADARR_ID"      "$MEDIA_S_LIBRARY_ID"  "$MEDIA_LAYOUT_ID" 3 0 3 3)
$(app_item "$MEDIA_BOARD_ID" "$BAZARR_ID"      "$MEDIA_S_LIBRARY_ID"  "$MEDIA_LAYOUT_ID" 6 0 3 3)
$(app_item "$MEDIA_BOARD_ID" "$PROWLARR_ID"    "$MEDIA_S_LIBRARY_ID"  "$MEDIA_LAYOUT_ID" 9 0 3 3)
$(app_item "$MEDIA_BOARD_ID" "$QBITTORRENT_ID" "$MEDIA_S_DLOAD_ID"    "$MEDIA_LAYOUT_ID" 0 0 3 3)
$(app_item "$MEDIA_BOARD_ID" "$NZBGET_ID"      "$MEDIA_S_DLOAD_ID"    "$MEDIA_LAYOUT_ID" 3 0 3 3)

-- =========================================================================
-- INFRASTRUCTURE BOARD SECTIONS + ITEMS
-- =========================================================================
INSERT INTO section (id, board_id, kind, x_offset, y_offset, name, options) VALUES
  ('$INFRA_S_OBS_ID',     '$INFRA_BOARD_ID', 'category', 0, 0, 'Observability',       '{"json": {}}'),
  ('$INFRA_S_SCM_ID',     '$INFRA_BOARD_ID', 'category', 0, 1, 'Source control & CD', '{"json": {}}'),
  ('$INFRA_S_STORAGE_ID', '$INFRA_BOARD_ID', 'category', 0, 2, 'Storage & DB',        '{"json": {}}'),
  ('$INFRA_S_NET_ID',     '$INFRA_BOARD_ID', 'category', 0, 3, 'Network & edge',      '{"json": {}}'),
  ('$INFRA_S_MATRIX_ID',  '$INFRA_BOARD_ID', 'category', 0, 4, 'Matrix / Identity',   '{"json": {}}'),
  ('$INFRA_S_APPS_ID',    '$INFRA_BOARD_ID', 'category', 0, 5, 'Apps',                '{"json": {}}');
$(app_item "$INFRA_BOARD_ID" "$GRAFANA_ID"       "$INFRA_S_OBS_ID"     "$INFRA_LAYOUT_ID" 0 0 3 3)
$(app_item "$INFRA_BOARD_ID" "$PROMETHEUS_ID"    "$INFRA_S_OBS_ID"     "$INFRA_LAYOUT_ID" 3 0 3 3)
$(app_item "$INFRA_BOARD_ID" "$ALERTMANAGER_ID"  "$INFRA_S_OBS_ID"     "$INFRA_LAYOUT_ID" 6 0 3 3)
$(app_item "$INFRA_BOARD_ID" "$TRAEFIK_ID"       "$INFRA_S_OBS_ID"     "$INFRA_LAYOUT_ID" 9 0 3 3)
$(app_item "$INFRA_BOARD_ID" "$GITLAB_ID"        "$INFRA_S_SCM_ID"     "$INFRA_LAYOUT_ID" 0 0 3 3)
$(app_item "$INFRA_BOARD_ID" "$REGISTRY_ID"      "$INFRA_S_SCM_ID"     "$INFRA_LAYOUT_ID" 3 0 3 3)
$(app_item "$INFRA_BOARD_ID" "$ARGOCD_ID"        "$INFRA_S_SCM_ID"     "$INFRA_LAYOUT_ID" 6 0 3 3)
$(app_item "$INFRA_BOARD_ID" "$MINIO_ID"         "$INFRA_S_STORAGE_ID" "$INFRA_LAYOUT_ID" 0 0 3 3)
$(app_item "$INFRA_BOARD_ID" "$MINIO_CONSOLE_ID" "$INFRA_S_STORAGE_ID" "$INFRA_LAYOUT_ID" 3 0 3 3)
$(app_item "$INFRA_BOARD_ID" "$PGADMIN_ID"       "$INFRA_S_STORAGE_ID" "$INFRA_LAYOUT_ID" 6 0 3 3)
$(app_item "$INFRA_BOARD_ID" "$PIHOLE_ID"        "$INFRA_S_NET_ID"     "$INFRA_LAYOUT_ID" 0 0 3 3)
$(app_item "$INFRA_BOARD_ID" "$PANGOLIN_ID"      "$INFRA_S_NET_ID"     "$INFRA_LAYOUT_ID" 3 0 3 3)
$(app_item "$INFRA_BOARD_ID" "$ELEMENT_ID"       "$INFRA_S_MATRIX_ID"  "$INFRA_LAYOUT_ID" 0 0 3 3)
$(app_item "$INFRA_BOARD_ID" "$SYNAPSE_ADMIN_ID" "$INFRA_S_MATRIX_ID"  "$INFRA_LAYOUT_ID" 3 0 3 3)
$(app_item "$INFRA_BOARD_ID" "$EZBOOKKEEPING_ID" "$INFRA_S_APPS_ID"    "$INFRA_LAYOUT_ID" 0 0 3 3)
$(app_item "$INFRA_BOARD_ID" "$SPORTARR_ID"      "$INFRA_S_APPS_ID"    "$INFRA_LAYOUT_ID" 3 0 3 3)

-- =========================================================================
-- READ BOARD SECTIONS + ITEMS
-- =========================================================================
INSERT INTO section (id, board_id, kind, x_offset, y_offset, name, options) VALUES
  ('$READ_S_NEWS_ID',     '$READ_BOARD_ID',  'category', 0, 0, 'Tech news (add RSS widgets here)', '{"json": {}}'),
  ('$READ_S_PERSONAL_ID', '$READ_BOARD_ID',  'category', 0, 1, 'Personal',                          '{"json": {}}');
$(app_item "$READ_BOARD_ID" "$CALENDAR_ID" "$READ_S_PERSONAL_ID" "$READ_LAYOUT_ID" 0 0 3 3)
$(app_item "$READ_BOARD_ID" "$GMAIL_ID"    "$READ_S_PERSONAL_ID" "$READ_LAYOUT_ID" 3 0 3 3)
$(app_item "$READ_BOARD_ID" "$DRIVE_ID"    "$READ_S_PERSONAL_ID" "$READ_LAYOUT_ID" 6 0 3 3)
$(app_item "$READ_BOARD_ID" "$PHOTOS_ID"   "$READ_S_PERSONAL_ID" "$READ_LAYOUT_ID" 9 0 3 3)

COMMIT;
EOF
)

# Pipe the generated SQL through kubectl exec on the engineer node.
echo "─── Seeding 3 boards into Homarr SQLite ───"
echo "$SQL" | ssh engineer-local "POD=\$(kubectl -n homarr get pod -l app.kubernetes.io/name=homarr -o jsonpath='{.items[0].metadata.name}'); kubectl -n homarr exec -i \$POD -- sqlite3 /appdata/db/db.sqlite"

# Verify.
echo
echo "─── Result ───"
ssh engineer-local "POD=\$(kubectl -n homarr get pod -l app.kubernetes.io/name=homarr -o jsonpath='{.items[0].metadata.name}'); kubectl -n homarr exec -i \$POD -- sqlite3 /appdata/db/db.sqlite 'SELECT name, (SELECT COUNT(*) FROM section WHERE board_id=board.id) AS sections, (SELECT COUNT(*) FROM item WHERE board_id=board.id) AS items FROM board;'"
