# Glance dashboard config. Rendered via sops.templates so every
# *.dobryops.com host is templated from SOPS — no plaintext domains in
# git. API tokens are injected via env at runtime (see glance-env in
# helm.nix) so rotating one doesn't reroll this whole Secret.
#
# Layout = "Mission Control" home page + integrated Media page +
# slim Mobile page. Bookmarks have selfh.st (`sh:`) / simple-icons
# (`si:`) icons per link.
#
# Template helpers (see widget-custom-api.go):
#   .JSON.{String,Int,Float,Bool,Array,Get,Exists} "<gjson-path>"
#   .Subrequest "name"     (cache in $var before {{ range }} loops)
#   add sub mul div  now (time.Time)  parseTime formatTime  duration  slice
#   toFloat(int)→float, toInt(float)→int
#   No sprig — toJson / parseJSON / humanizeBytes etc. don't exist.
#
# Prometheus queries hardcode instance="192.0.2.10:9100"; WG metrics
# carry instance="engineer" from monitoring/.../wireguard-scrape.nix.
#
# In-cluster Service URLs use the *Service* port (the tunnel-IP-side
# port), NOT the pod-side targetPort. uptime-kuma exposes :8097
# (pod listens on 3001), speedtest-tracker :8099 (pod on 80), etc.
{ config, ... }:

let
  prom    = "http://kube-prometheus-stack-prometheus.monitoring.svc.cluster.local:9090";
  amgr    = "http://kube-prometheus-stack-alertmanager.monitoring.svc.cluster.local:9093";
  kuma    = "http://uptime-kuma.monitoring.svc.cluster.local:8097";
  spdtest = "http://speedtest-tracker.monitoring.svc.cluster.local:8099";

  promQuery = q: "${prom}/api/v1/query?query=${q}";

  # Wide hardcoded date range for *arr calendars — Sonarr/Radarr
  # require start+end. Refresh every couple years or so.
  arrStart = "2026-01-01T00:00:00Z";
  arrEnd   = "2027-06-01T00:00:00Z";

in
{
  sops.templates."glance/config.yaml" = {
    content = ''
      apiVersion: v1
      kind: Secret
      metadata:
        name: glance-config
        namespace: dashboard
      type: Opaque
      stringData:
        glance.yml: |
          theme:
            background-color: 240 8 9
            primary-color: 43 50 70
            negative-color: 0 70 60
            contrast-multiplier: 1.1

          server:
            host: 0.0.0.0
            port: 8080
            base-url: ""

          pages:
            # ────────────────────────────────────────────────────────────
            # HOME
            # ────────────────────────────────────────────────────────────
            - name: Home
              columns:
                # ── left sidebar ──────────────────────────────────────
                - size: small
                  widgets:
                    - type: custom-api
                      title: Engineer
                      cache: 30s
                      url: ${promQuery "(1-avg(rate(node_cpu_seconds_total%7Binstance=%22192.0.2.10:9100%22,mode=%22idle%22%7D%5B5m%5D)))*100"}
                      subrequests:
                        ram:
                          url: ${promQuery "(1-node_memory_MemAvailable_bytes%7Binstance=%22192.0.2.10:9100%22%7D/node_memory_MemTotal_bytes%7Binstance=%22192.0.2.10:9100%22%7D)*100"}
                        disk:
                          url: ${promQuery "(1-node_filesystem_avail_bytes%7Binstance=%22192.0.2.10:9100%22,mountpoint=%22/%22%7D/node_filesystem_size_bytes%7Binstance=%22192.0.2.10:9100%22,mountpoint=%22/%22%7D)*100"}
                        uptime:
                          url: ${promQuery "node_time_seconds%7Binstance=%22192.0.2.10:9100%22%7D-node_boot_time_seconds%7Binstance=%22192.0.2.10:9100%22%7D"}
                      template: |
                        {{ $ram     := .Subrequest "ram" }}
                        {{ $disk    := .Subrequest "disk" }}
                        {{ $uptime  := .Subrequest "uptime" }}
                        {{ $cpuVal  := .JSON.Float "data.result.0.value.1" }}
                        {{ $ramVal  := $ram.JSON.Float "data.result.0.value.1" }}
                        {{ $diskVal := $disk.JSON.Float "data.result.0.value.1" }}
                        <div class="flex flex-column gap-10">
                          <div>
                            <div class="flex justify-between">
                              <span class="size-h6 color-paragraph">CPU</span>
                              <span class="size-h5">{{ printf "%.1f" $cpuVal }}%</span>
                            </div>
                            <div style="height:4px;background:rgba(255,255,255,0.08);border-radius:2px;margin-top:4px">
                              <div style="width:{{ printf "%.1f" $cpuVal }}%;height:100%;background:var(--color-primary);border-radius:2px"></div>
                            </div>
                          </div>
                          <div>
                            <div class="flex justify-between">
                              <span class="size-h6 color-paragraph">RAM</span>
                              <span class="size-h5">{{ printf "%.1f" $ramVal }}%</span>
                            </div>
                            <div style="height:4px;background:rgba(255,255,255,0.08);border-radius:2px;margin-top:4px">
                              <div style="width:{{ printf "%.1f" $ramVal }}%;height:100%;background:var(--color-primary);border-radius:2px"></div>
                            </div>
                          </div>
                          <div>
                            <div class="flex justify-between">
                              <span class="size-h6 color-paragraph">Disk /</span>
                              <span class="size-h5">{{ printf "%.1f" $diskVal }}%</span>
                            </div>
                            <div style="height:4px;background:rgba(255,255,255,0.08);border-radius:2px;margin-top:4px">
                              <div style="width:{{ printf "%.1f" $diskVal }}%;height:100%;background:var(--color-primary);border-radius:2px"></div>
                            </div>
                          </div>
                          <div class="flex justify-between">
                            <span class="size-h6 color-paragraph">Uptime</span>
                            <span class="size-base">{{ printf "%.0fh" (div ($uptime.JSON.Float "data.result.0.value.1") 3600) }}</span>
                          </div>
                        </div>

                    - type: custom-api
                      title: Pangolin VPS
                      cache: 30s
                      url: ${promQuery "time()-wireguard_latest_handshake_seconds%7Binstance=%22engineer%22%7D"}
                      subrequests:
                        # Bytes since the 1st of the current calendar
                        # month — matches Hetzner's 20 TB/mo billing
                        # cycle. Derived via a PrometheusRule in
                        # workloads/namespace/monitoring/apps/
                        # kube-prometheus-stack/wireguard-monthly.nix
                        # that captures a marker at month boundaries.
                        # rx side (engineer.rx ≈ VPS.tx) is what counts
                        # against Hetzner's "Traffic out" quota.
                        sent:
                          url: ${promQuery "wireguard_sent_bytes_since_month_start%7Binstance=%22engineer%22%7D"}
                        recv:
                          url: ${promQuery "wireguard_received_bytes_since_month_start%7Binstance=%22engineer%22%7D"}
                      template: |
                        {{ $sent := .Subrequest "sent" }}
                        {{ $recv := .Subrequest "recv" }}
                        <div class="flex flex-column gap-7">
                          <div class="flex justify-between">
                            <span class="size-h6 color-paragraph">handshake</span>
                            <span class="size-h5">{{ printf "%.0fs ago" (.JSON.Float "data.result.0.value.1") }}</span>
                          </div>
                          <div class="flex justify-between">
                            <span class="size-h6 color-paragraph">↑ tx (mo)</span>
                            <span class="size-base">{{ printf "%.2f GB" (div ($sent.JSON.Float "data.result.0.value.1") 1073741824.0) }}</span>
                          </div>
                          <div class="flex justify-between">
                            <span class="size-h6 color-paragraph">↓ rx (mo)</span>
                            <span class="size-base">{{ printf "%.2f GB" (div ($recv.JSON.Float "data.result.0.value.1") 1073741824.0) }}</span>
                          </div>
                          <div class="flex justify-between">
                            <span class="size-h6 color-paragraph">remote</span>
                            <span class="size-base">203.0.113.10</span>
                          </div>
                        </div>

                    - type: custom-api
                      title: Cluster
                      cache: 60s
                      url: ${promQuery "count(kube_pod_info)"}
                      subrequests:
                        ns:
                          url: ${promQuery "count(kube_namespace_status_phase%7Bphase=%22Active%22%7D)"}
                        dep:
                          url: ${promQuery "count(kube_deployment_metadata_generation)"}
                        ready:
                          url: ${promQuery "count(kube_pod_status_phase%7Bphase=%22Running%22%7D)"}
                      template: |
                        {{ $ns    := .Subrequest "ns" }}
                        {{ $dep   := .Subrequest "dep" }}
                        {{ $ready := .Subrequest "ready" }}
                        <div class="flex flex-column gap-5">
                          <div class="flex justify-between">
                            <span>pods</span>
                            <span class="color-highlight">{{ .JSON.String "data.result.0.value.1" }} · {{ $ready.JSON.String "data.result.0.value.1" }} ready</span>
                          </div>
                          <div class="flex justify-between">
                            <span>namespaces</span>
                            <span class="color-highlight">{{ $ns.JSON.String "data.result.0.value.1" }}</span>
                          </div>
                          <div class="flex justify-between">
                            <span>deployments</span>
                            <span class="color-highlight">{{ $dep.JSON.String "data.result.0.value.1" }}</span>
                          </div>
                        </div>

                    - type: custom-api
                      title: Active alerts
                      cache: 30s
                      url: ${amgr}/api/v2/alerts?active=true&silenced=false&inhibited=false
                      template: |
                        {{ $alerts := .JSON.Array "" }}
                        {{ if eq (len $alerts) 0 }}
                          <p class="color-positive">none firing</p>
                        {{ else }}
                          <ul class="list collapsible-container" data-collapse-after="5">
                            {{ range $alerts }}
                              <li><span class="color-negative">●</span> {{ .String "labels.alertname" }} · {{ .String "labels.severity" }}</li>
                            {{ end }}
                          </ul>
                        {{ end }}

                # ── center / main column ──────────────────────────────
                - size: full
                  widgets:
                    - type: search
                      search-engine: https://${config.sops.placeholder."pangolin/resources/search/domain"}/search?q={QUERY}
                      new-tab: true
                      bangs:
                        - title: GitHub
                          shortcut: "!gh"
                          url: https://github.com/search?q={QUERY}
                        - title: NixOS packages
                          shortcut: "!np"
                          url: https://search.nixos.org/packages?query={QUERY}
                        - title: NixOS options
                          shortcut: "!no"
                          url: https://search.nixos.org/options?query={QUERY}
                        - title: Hacker News
                          shortcut: "!hn"
                          url: https://hn.algolia.com/?q={QUERY}

                    # 6 balanced groups so glance lays them out 3×2.
                    # A 4-group layout wraps to 3+1 and orphans the last.
                    - type: bookmarks
                      groups:
                        - title: Dev
                          links:
                            - title: GitLab
                              url: https://${config.sops.placeholder."pangolin/resources/gitlab/domain"}
                              icon: si:gitlab
                            - title: ArgoCD
                              url: https://${config.sops.placeholder."pangolin/resources/argocd/domain"}
                              icon: si:argo
                            - title: pgAdmin
                              url: https://${config.sops.placeholder."pangolin/resources/pgadmin/domain"}
                              icon: si:postgresql
                        - title: Monitor
                          links:
                            - title: Grafana
                              url: https://${config.sops.placeholder."pangolin/resources/grafana/domain"}
                              icon: si:grafana
                            - title: Prometheus
                              url: https://${config.sops.placeholder."pangolin/resources/prometheus/domain"}
                              icon: si:prometheus
                            - title: Alertmanager
                              url: https://${config.sops.placeholder."pangolin/resources/alertmanager/domain"}
                              icon: di:alertmanager
                        - title: Admin
                          links:
                            - title: Pi-hole
                              url: https://${config.sops.placeholder."pangolin/resources/pihole/domain"}
                              icon: si:pihole
                            - title: MinIO
                              url: https://${config.sops.placeholder."pangolin/resources/minio_console/domain"}
                              icon: si:minio
                        - title: Comms
                          links:
                            - title: Matrix
                              url: https://${config.sops.placeholder."pangolin/resources/element/domain"}
                              icon: si:element
                            - title: Synapse Admin
                              url: https://${config.sops.placeholder."pangolin/resources/synapse_admin/domain"}
                              icon: si:matrix
                            - title: Mail
                              url: https://${config.sops.placeholder."pangolin/resources/mailadmin/domain"}
                              icon: di:stalwart
                        - title: Personal
                          links:
                            - title: ezBookkeeping
                              url: https://${config.sops.placeholder."pangolin/resources/ezbookkeeping/domain"}
                              icon: di:ezbookkeeping
                            - title: Blog
                              url: https://${config.sops.placeholder."pangolin/resources/whoami/domain"}
                              icon: di:hashnode
                        - title: Social
                          links:
                            - title: YouTube
                              url: https://www.youtube.com/
                              icon: si:youtube
                            - title: Reddit
                              url: https://www.reddit.com/
                              icon: si:reddit
                            - title: NixOS Discourse
                              url: https://discourse.nixos.org/
                              icon: si:nixos

                    # SERVICES — Uptime Kuma's status-page heartbeat JSON.
                    # Emits a section per group (Media, Dev, Ops, Comms,
                    # Personal, Dashboard, Private) with its own grid.
                    - type: custom-api
                      title: Services
                      cache: 1m
                      url: ${kuma}/api/status-page/homelab
                      subrequests:
                        hb:
                          url: ${kuma}/api/status-page/heartbeat/homelab
                      template: |
                        {{ $hb := .Subrequest "hb" }}
                        <div class="flex flex-column gap-10">
                        {{ range .JSON.Array "publicGroupList" }}
                          <div>
                            <p class="size-h6 color-paragraph margin-bottom-3">{{ .String "name" | upper }}</p>
                            <ul class="list list-gap-2">
                            {{ range .Array "monitorList" }}
                              {{ $id := .String "id" }}
                              {{ $name := .String "name" }}
                              {{ $statusPath := printf "heartbeatList.%s|@reverse|0.status" $id }}
                              {{ $pingPath   := printf "heartbeatList.%s|@reverse|0.ping"   $id }}
                              {{ $status := $hb.JSON.Int $statusPath }}
                              {{ $ping   := $hb.JSON.Int $pingPath }}
                              <li class="flex justify-between">
                                <span>
                                  {{ if eq $status 1 }}<span class="color-positive">●</span>{{ else if eq $status 0 }}<span class="color-negative">●</span>{{ else }}<span class="color-paragraph">●</span>{{ end }}
                                  {{ $name }}
                                </span>
                                {{ if gt $ping 0 }}<span class="size-h6 color-paragraph">{{ $ping }} ms</span>{{ end }}
                              </li>
                            {{ end }}
                            </ul>
                          </div>
                        {{ end }}
                        </div>

                    - type: rss
                      title: News
                      limit: 12
                      collapse-after: 5
                      cache: 30m
                      feeds:
                        - url: https://news.ycombinator.com/rss
                          title: Hacker News
                        - url: https://9to5linux.com/feed
                          title: 9to5Linux
                        - url: https://www.bleepingcomputer.com/feed/
                          title: Bleeping
                        - url: https://media.rss.com/linkarzu/feed.xml
                          title: Linkarzu

                # ── right sidebar ─────────────────────────────────────
                - size: small
                  widgets:
                    - type: bookmarks
                      groups:
                        - title: Infra
                          links:
                            - title: Pangolin
                              url: https://pangolin.dobryops.com
                              icon: di:pangolin
                            - title: Traefik
                              url: https://${config.sops.placeholder."pangolin/resources/traefik_dashboard/domain"}
                              icon: si:traefikproxy
                            - title: Hetzner
                              url: https://console.hetzner.com/projects/11019344/dashboard
                              icon: si:hetzner

                    # NIXPKGS DRIFT — homelab-overkill. Sourced from GitHub
                    # raw since the repo isn't mirrored to the in-cluster
                    # GitLab. No auth needed for public read.
                    - type: custom-api
                      title: nixpkgs — homelab-overkill
                      cache: 30m
                      url: https://raw.githubusercontent.com/bovf/homelab-overkill/main/flake.lock
                      subrequests:
                        head:
                          url: https://api.github.com/repos/NixOS/nixpkgs/commits/nixos-unstable
                      template: |
                        {{ $head    := .Subrequest "head" }}
                        {{ $pinSha  := .JSON.String "nodes.nixpkgs.locked.rev" }}
                        {{ $headSha := $head.JSON.String "sha" }}
                        {{ if eq (len $pinSha) 0 }}
                          <p class="color-negative">flake.lock unreadable</p>
                        {{ else }}
                          <div class="flex flex-column gap-5">
                            <div class="flex justify-between"><span>pin</span><span class="color-highlight">{{ slice $pinSha 0 8 }}</span></div>
                            <div class="flex justify-between"><span>head</span><span class="color-highlight">{{ slice $headSha 0 8 }}</span></div>
                            {{ if eq $pinSha $headSha }}
                              <div class="flex justify-between"><span>status</span><span class="color-positive">in sync</span></div>
                            {{ else }}
                              <div class="flex justify-between"><span>status</span><span class="color-negative">behind</span></div>
                            {{ end }}
                          </div>
                        {{ end }}

                    # NIXPKGS DRIFT — pl-badwater (from in-cluster GitLab).
                    - type: custom-api
                      title: nixpkgs — pl-badwater
                      cache: 30m
                      url: https://${config.sops.placeholder."pangolin/resources/gitlab/domain"}/api/v4/projects/bovf%2Fpl-badwater/repository/files/flake.lock/raw?ref=main
                      headers:
                        PRIVATE-TOKEN: ''${GITLAB_TOKEN}
                      subrequests:
                        head:
                          url: https://api.github.com/repos/NixOS/nixpkgs/commits/nixos-unstable
                      template: |
                        {{ $head    := .Subrequest "head" }}
                        {{ $pinSha  := .JSON.String "nodes.nixpkgs.locked.rev" }}
                        {{ $headSha := $head.JSON.String "sha" }}
                        {{ if eq (len $pinSha) 0 }}
                          <p class="color-negative">flake.lock unreadable</p>
                        {{ else }}
                          <div class="flex flex-column gap-5">
                            <div class="flex justify-between"><span>pin</span><span class="color-highlight">{{ slice $pinSha 0 8 }}</span></div>
                            <div class="flex justify-between"><span>head</span><span class="color-highlight">{{ slice $headSha 0 8 }}</span></div>
                            {{ if eq $pinSha $headSha }}
                              <div class="flex justify-between"><span>status</span><span class="color-positive">in sync</span></div>
                            {{ else }}
                              <div class="flex justify-between"><span>status</span><span class="color-negative">behind</span></div>
                            {{ end }}
                          </div>
                        {{ end }}

                    # SPEEDTEST — latest result from speedtest-tracker v1.14+
                    # Requires a Sanctum bearer token. Generate one in the
                    # UI: Settings → API Tokens → Create, then set
                    # speedtest/api_token in sops.
                    - type: custom-api
                      title: Speedtest
                      cache: 5m
                      url: ${spdtest}/api/v1/results/latest
                      headers:
                        Authorization: Bearer ''${SPEEDTEST_TOKEN}
                        Accept: application/json
                      template: |
                        <div class="flex flex-column gap-5">
                          <div class="flex justify-between"><span>↓ download</span><span class="size-h4">{{ printf "%.0f Mbps" (div (.JSON.Float "data.download") 1000000.0) }}</span></div>
                          <div class="flex justify-between"><span>↑ upload</span><span class="size-h4">{{ printf "%.0f Mbps" (div (.JSON.Float "data.upload") 1000000.0) }}</span></div>
                          <div class="flex justify-between"><span>· ping</span><span class="size-h4">{{ printf "%.0f ms" (.JSON.Float "data.ping") }}</span></div>
                        </div>

                    - type: weather
                      location: Sofia, Bulgaria
                      units: metric
                      hour-format: 24h

            # ────────────────────────────────────────────────────────────
            # MEDIA
            # ────────────────────────────────────────────────────────────
            - name: Media
              columns:
                # ── left ──────────────────────────────────────────────
                - size: small
                  widgets:
                    # Jellyfin library counts — Items/Counts is auth'd
                    # via api_key query param. In-cluster Service so we
                    # skip traefik/TLS overhead for this internal fetch.
                    - type: custom-api
                      title: Jellyfin Library
                      cache: 5m
                      url: http://jellyfin.media.svc.cluster.local:8096/Items/Counts?api_key=''${JELLYFIN_KEY}
                      template: |
                        <div class="flex flex-column gap-5">
                          <div class="flex justify-between"><span>Movies</span><span class="color-highlight">{{ .JSON.Int "MovieCount" }}</span></div>
                          <div class="flex justify-between"><span>Shows</span><span class="color-highlight">{{ .JSON.Int "SeriesCount" }}</span></div>
                          <div class="flex justify-between"><span>Episodes</span><span class="color-highlight">{{ .JSON.Int "EpisodeCount" }}</span></div>
                          <div class="flex justify-between"><span>Songs</span><span class="color-highlight">{{ .JSON.Int "SongCount" }}</span></div>
                        </div>

                    # Active Jellyfin streams
                    - type: custom-api
                      title: Active streams
                      cache: 30s
                      url: http://jellyfin.media.svc.cluster.local:8096/Sessions?api_key=''${JELLYFIN_KEY}&activeWithinSeconds=60
                      template: |
                        {{ $playing := 0 }}
                        {{ range .JSON.Array "" }}
                          {{ if .Exists "NowPlayingItem" }}
                            {{ $playing = add $playing 1 }}
                          {{ end }}
                        {{ end }}
                        {{ if eq $playing 0 }}
                          <p class="color-paragraph">No active streams</p>
                        {{ else }}
                          <ul class="list">
                            {{ range .JSON.Array "" }}
                              {{ if .Exists "NowPlayingItem" }}
                                <li><span class="color-positive">●</span> {{ .String "UserName" }} · {{ .String "NowPlayingItem.Name" }}</li>
                              {{ end }}
                            {{ end }}
                          </ul>
                        {{ end }}

                    - type: bookmarks
                      title: Library
                      groups:
                        - title: ""
                          links:
                            - title: Jellyfin
                              url: https://${config.sops.placeholder."pangolin/resources/jellyfin/domain"}
                              icon: si:jellyfin
                            - title: Jellyseerr
                              url: https://${config.sops.placeholder."pangolin/resources/jellyseerr/domain"}
                              icon: si:jellyseerr

                # ── center ────────────────────────────────────────────
                - size: full
                  widgets:
                    # Sonarr upcoming episodes
                    - type: custom-api
                      title: Upcoming — TV
                      cache: 10m
                      url: http://sonarr.media.svc.cluster.local:8989/api/v3/calendar?start=${arrStart}&end=${arrEnd}&includeSeries=true&unmonitored=false
                      headers:
                        X-Api-Key: ''${SONARR_KEY}
                        Accept: application/json
                      template: |
                        {{ $now := now }}
                        {{ $items := .JSON.Array "" }}
                        {{ if eq (len $items) 0 }}
                          <p class="color-paragraph">Nothing scheduled</p>
                        {{ else }}
                          <ul class="list collapsible-container" data-collapse-after="6">
                            {{ range $items }}
                              {{ $air := parseTime "2006-01-02T15:04:05Z" (.String "airDateUtc") }}
                              {{ if gt $air.Unix $now.Unix }}
                                <li>
                                  <span class="color-highlight">{{ .String "series.title" }}</span>
                                  · S{{ printf "%02d" (.Int "seasonNumber") }}E{{ printf "%02d" (.Int "episodeNumber") }}
                                  · <span class="color-paragraph">{{ formatTime "Jan 02" $air }}</span>
                                </li>
                              {{ end }}
                            {{ end }}
                          </ul>
                        {{ end }}

                    # Radarr upcoming movies
                    - type: custom-api
                      title: Coming Soon — Movies
                      cache: 10m
                      url: http://radarr.media.svc.cluster.local:7878/api/v3/calendar?start=${arrStart}&end=${arrEnd}&unmonitored=false
                      headers:
                        X-Api-Key: ''${RADARR_KEY}
                        Accept: application/json
                      template: |
                        {{ $now := now }}
                        {{ $items := .JSON.Array "" }}
                        {{ if eq (len $items) 0 }}
                          <p class="color-paragraph">Nothing scheduled</p>
                        {{ else }}
                          <ul class="list collapsible-container" data-collapse-after="6">
                            {{ range $items }}
                              {{ $dateStr := .String "physicalRelease" }}
                              {{ if eq $dateStr "" }}{{ $dateStr = .String "digitalRelease" }}{{ end }}
                              {{ if ne $dateStr "" }}
                                {{ $rel := parseTime "2006-01-02T15:04:05Z" $dateStr }}
                                {{ if gt $rel.Unix $now.Unix }}
                                  <li>
                                    <span class="color-highlight">{{ .String "title" }}</span>
                                    · <span class="color-paragraph">{{ formatTime "Jan 02" $rel }}</span>
                                  </li>
                                {{ end }}
                              {{ end }}
                            {{ end }}
                          </ul>
                        {{ end }}

                    # Jellyseerr request counts. The Global API key in
                    # Settings → General authenticates but lacks user
                    # context — /api/v1/request returns 403 because
                    # requests are per-user. /api/v1/request/count is
                    # the system-level endpoint that works with just
                    # the global key.
                    - type: custom-api
                      title: Requests
                      cache: 5m
                      url: http://jellyseerr.media.svc.cluster.local:5055/api/v1/request/count
                      headers:
                        X-Api-Key: ''${JELLYSEERR_KEY}
                        Accept: application/json
                      template: |
                        <div class="flex flex-column gap-5">
                          <div class="flex justify-between"><span>pending</span><span class="size-h4 color-highlight">{{ .JSON.Int "pending" }}</span></div>
                          <div class="flex justify-between"><span>processing</span><span class="size-h4">{{ .JSON.Int "processing" }}</span></div>
                          <div class="flex justify-between"><span>available</span><span class="size-h4 color-positive">{{ .JSON.Int "available" }}</span></div>
                          <div class="flex justify-between"><span>declined</span><span class="size-h4 color-paragraph">{{ .JSON.Int "declined" }}</span></div>
                        </div>

                    # *arr stack — Sportarr folded in alongside the others.
                    - type: bookmarks
                      title: Stack
                      groups:
                        - title: ""
                          links:
                            - title: Sonarr
                              url: https://${config.sops.placeholder."pangolin/resources/sonarr/domain"}
                              icon: si:sonarr
                            - title: Radarr
                              url: https://${config.sops.placeholder."pangolin/resources/radarr/domain"}
                              icon: si:radarr
                            - title: Sportarr
                              url: https://${config.sops.placeholder."pangolin/resources/sportarr/domain"}
                              icon: di:sonarr
                            - title: Prowlarr
                              url: https://${config.sops.placeholder."pangolin/resources/prowlarr/domain"}
                              icon: si:prowlarr
                            - title: Bazarr
                              url: https://${config.sops.placeholder."pangolin/resources/bazarr/domain"}
                              icon: di:bazarr

                # ── right ─────────────────────────────────────────────
                - size: small
                  widgets:
                    - type: bookmarks
                      title: Queues
                      groups:
                        - title: ""
                          links:
                            - title: qBittorrent
                              url: https://${config.sops.placeholder."pangolin/resources/qbittorrent/domain"}
                              icon: si:qbittorrent
                            - title: NZBGet
                              url: https://${config.sops.placeholder."pangolin/resources/nzbget/domain"}
                              icon: di:nzbget

                    # *arr health from Prowlarr's perspective — Prowlarr
                    # pings every connected indexer + downloader on
                    # /api/v1/health and returns issue list.
                    - type: custom-api
                      title: Indexer Health
                      cache: 5m
                      url: http://prowlarr.media.svc.cluster.local:9696/api/v1/health
                      headers:
                        X-Api-Key: ''${PROWLARR_KEY}
                        Accept: application/json
                      template: |
                        {{ $issues := .JSON.Array "" }}
                        {{ if eq (len $issues) 0 }}
                          <p class="color-positive">All healthy</p>
                        {{ else }}
                          <ul class="list">
                            {{ range $issues }}
                              <li><span class="color-negative">●</span> {{ .String "source" }} · {{ .String "message" }}</li>
                            {{ end }}
                          </ul>
                        {{ end }}

            # ────────────────────────────────────────────────────────────
            # MOBILE
            # ────────────────────────────────────────────────────────────
            - name: Mobile
              hide-desktop-navigation: false
              width: slim
              columns:
                - size: full
                  widgets:
                    - type: search
                      search-engine: https://${config.sops.placeholder."pangolin/resources/search/domain"}/search?q={QUERY}
                      new-tab: true

                    - type: bookmarks
                      groups:
                        - title: Daily
                          links:
                            - title: Jellyfin
                              url: https://${config.sops.placeholder."pangolin/resources/jellyfin/domain"}
                              icon: si:jellyfin
                            - title: Matrix
                              url: https://${config.sops.placeholder."pangolin/resources/element/domain"}
                              icon: si:element
                            - title: Grafana
                              url: https://${config.sops.placeholder."pangolin/resources/grafana/domain"}
                              icon: si:grafana
                            - title: GitLab
                              url: https://${config.sops.placeholder."pangolin/resources/gitlab/domain"}
                              icon: si:gitlab

                    - type: custom-api
                      title: Engineer
                      cache: 30s
                      url: ${promQuery "(1-avg(rate(node_cpu_seconds_total%7Binstance=%22192.0.2.10:9100%22,mode=%22idle%22%7D%5B5m%5D)))*100"}
                      subrequests:
                        ram:
                          url: ${promQuery "(1-node_memory_MemAvailable_bytes%7Binstance=%22192.0.2.10:9100%22%7D/node_memory_MemTotal_bytes%7Binstance=%22192.0.2.10:9100%22%7D)*100"}
                        disk:
                          url: ${promQuery "(1-node_filesystem_avail_bytes%7Binstance=%22192.0.2.10:9100%22,mountpoint=%22/%22%7D/node_filesystem_size_bytes%7Binstance=%22192.0.2.10:9100%22,mountpoint=%22/%22%7D)*100"}
                        uptime:
                          url: ${promQuery "node_time_seconds%7Binstance=%22192.0.2.10:9100%22%7D-node_boot_time_seconds%7Binstance=%22192.0.2.10:9100%22%7D"}
                      template: |
                        {{ $ram     := .Subrequest "ram" }}
                        {{ $disk    := .Subrequest "disk" }}
                        {{ $uptime  := .Subrequest "uptime" }}
                        {{ $cpuVal  := .JSON.Float "data.result.0.value.1" }}
                        {{ $ramVal  := $ram.JSON.Float "data.result.0.value.1" }}
                        {{ $diskVal := $disk.JSON.Float "data.result.0.value.1" }}
                        <div class="flex flex-column gap-10">
                          <div>
                            <div class="flex justify-between">
                              <span class="size-h6 color-paragraph">CPU</span>
                              <span class="size-h5">{{ printf "%.1f" $cpuVal }}%</span>
                            </div>
                            <div style="height:4px;background:rgba(255,255,255,0.08);border-radius:2px;margin-top:4px">
                              <div style="width:{{ printf "%.1f" $cpuVal }}%;height:100%;background:var(--color-primary);border-radius:2px"></div>
                            </div>
                          </div>
                          <div>
                            <div class="flex justify-between">
                              <span class="size-h6 color-paragraph">RAM</span>
                              <span class="size-h5">{{ printf "%.1f" $ramVal }}%</span>
                            </div>
                            <div style="height:4px;background:rgba(255,255,255,0.08);border-radius:2px;margin-top:4px">
                              <div style="width:{{ printf "%.1f" $ramVal }}%;height:100%;background:var(--color-primary);border-radius:2px"></div>
                            </div>
                          </div>
                          <div>
                            <div class="flex justify-between">
                              <span class="size-h6 color-paragraph">Disk /</span>
                              <span class="size-h5">{{ printf "%.1f" $diskVal }}%</span>
                            </div>
                            <div style="height:4px;background:rgba(255,255,255,0.08);border-radius:2px;margin-top:4px">
                              <div style="width:{{ printf "%.1f" $diskVal }}%;height:100%;background:var(--color-primary);border-radius:2px"></div>
                            </div>
                          </div>
                          <div class="flex justify-between">
                            <span class="size-h6 color-paragraph">Uptime</span>
                            <span class="size-base">{{ printf "%.0fh" (div ($uptime.JSON.Float "data.result.0.value.1") 3600) }}</span>
                          </div>
                        </div>

                    - type: weather
                      location: Sofia, Bulgaria
                      units: metric
                      hour-format: 24h

                    - type: rss
                      title: News
                      limit: 6
                      cache: 30m
                      feeds:
                        - url: https://news.ycombinator.com/rss
                          title: HN
                        - url: https://9to5linux.com/feed
                          title: 9to5Linux
                        - url: https://www.bleepingcomputer.com/feed/
                          title: Bleeping
                        - url: https://media.rss.com/linkarzu/feed.xml
                          title: Linkarzu
    '';
    path  = "/var/lib/rancher/k3s/server/manifests/glance-config.yaml";
    owner = "root";
    group = "root";
    mode  = "0644";
  };
}
