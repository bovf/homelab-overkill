# Glance dashboard config. Rendered via sops.templates so every
# *.dobryops.com host is templated from SOPS — no plaintext domains in
# git. The GitLab read token is injected via env at runtime (see
# helm.nix' glance-env Secret) so it's not baked into this rendered
# Secret either.
#
# Layout = "Mission Control": 3 columns, left/right are sidebars, middle
# is the daily-driver feed. Media + Mobile pages are wired but stay
# light (mostly bookmarks) — we flesh them out in follow-ups once Kuma
# + the *arr integrations are confirmed live.
#
# Template helpers available in custom-api widget (see
# glance/widget-custom-api.go):
#   .JSON.{String,Int,Float,Bool,Array,Get,Exists} "path"   (gjson syntax)
#   .Subrequest "name"     (returns the same shape; cache it in a var
#                           before entering range loops since `.` shifts)
#   add sub mul div  parseTime formatTime  now  duration  slice
#   No sprig — toJson / parseJSON / humanizeBytes etc. don't exist.
#
# Prometheus queries hardcode instance="192.0.2.10:9100" for the
# node-exporter on engineer; WireGuard metrics carry instance="engineer"
# from the ScrapeConfig in monitoring/.../wireguard-scrape.nix.
{ config, ... }:

let
  # Cluster-internal Service URLs. Not secrets, just inconvenient strings.
  prom    = "http://kube-prometheus-stack-prometheus.monitoring.svc.cluster.local:9090";
  amgr    = "http://kube-prometheus-stack-alertmanager.monitoring.svc.cluster.local:9093";
  kuma    = "http://uptime-kuma.monitoring.svc.cluster.local:3001";
  spdtest = "http://speedtest-tracker.monitoring.svc.cluster.local:80";

  promQuery = q: "${prom}/api/v1/query?query=${q}";
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
                        {{ $ram    := .Subrequest "ram" }}
                        {{ $disk   := .Subrequest "disk" }}
                        {{ $uptime := .Subrequest "uptime" }}
                        <div class="flex flex-column gap-7">
                          <div>
                            <p class="size-h6 color-paragraph">CPU</p>
                            <p class="size-h3">{{ printf "%.1f" (.JSON.Float "data.result.0.value.1") }}%</p>
                          </div>
                          <div>
                            <p class="size-h6 color-paragraph">RAM</p>
                            <p class="size-h3">{{ printf "%.1f" ($ram.JSON.Float "data.result.0.value.1") }}%</p>
                          </div>
                          <div>
                            <p class="size-h6 color-paragraph">Disk /</p>
                            <p class="size-h3">{{ printf "%.1f" ($disk.JSON.Float "data.result.0.value.1") }}%</p>
                          </div>
                          <div>
                            <p class="size-h6 color-paragraph">Uptime</p>
                            <p class="size-base">{{ printf "%.0f hours" (div ($uptime.JSON.Float "data.result.0.value.1") 3600) }}</p>
                          </div>
                        </div>

                    - type: custom-api
                      title: Pangolin VPS
                      cache: 30s
                      url: ${promQuery "time()-wireguard_latest_handshake_seconds%7Binstance=%22engineer%22%7D"}
                      subrequests:
                        sent:
                          url: ${promQuery "wireguard_sent_bytes_total%7Binstance=%22engineer%22%7D"}
                        recv:
                          url: ${promQuery "wireguard_received_bytes_total%7Binstance=%22engineer%22%7D"}
                      template: |
                        {{ $sent := .Subrequest "sent" }}
                        {{ $recv := .Subrequest "recv" }}
                        <div class="flex flex-column gap-7">
                          <div>
                            <p class="size-h6 color-paragraph">kwg handshake</p>
                            <p class="size-h4">{{ printf "%.0fs ago" (.JSON.Float "data.result.0.value.1") }}</p>
                          </div>
                          <div>
                            <p class="size-h6 color-paragraph">tx</p>
                            <p class="size-base">{{ printf "%.2f GB" (div ($sent.JSON.Float "data.result.0.value.1") 1073741824.0) }}</p>
                          </div>
                          <div>
                            <p class="size-h6 color-paragraph">rx</p>
                            <p class="size-base">{{ printf "%.2f GB" (div ($recv.JSON.Float "data.result.0.value.1") 1073741824.0) }}</p>
                          </div>
                          <div>
                            <p class="size-h6 color-paragraph">remote</p>
                            <p class="size-base">203.0.113.10</p>
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

                    - type: bookmarks
                      groups:
                        - title: Dev
                          links:
                            - title: GitLab
                              url: https://${config.sops.placeholder."pangolin/resources/gitlab/domain"}
                            - title: ArgoCD
                              url: https://${config.sops.placeholder."pangolin/resources/argocd/domain"}
                        - title: Social
                          links:
                            - title: YouTube
                              url: https://www.youtube.com/
                            - title: Reddit
                              url: https://www.reddit.com/
                            - title: NixOS Discourse
                              url: https://discourse.nixos.org/
                        - title: Ops
                          links:
                            - title: Grafana
                              url: https://${config.sops.placeholder."pangolin/resources/grafana/domain"}
                            - title: Prometheus
                              url: https://${config.sops.placeholder."pangolin/resources/prometheus/domain"}
                            - title: Alertmanager
                              url: https://${config.sops.placeholder."pangolin/resources/alertmanager/domain"}
                            - title: Pi-hole
                              url: https://${config.sops.placeholder."pangolin/resources/pihole/domain"}
                            - title: Pangolin
                              url: https://pangolin.dobryops.com
                            - title: MinIO
                              url: https://${config.sops.placeholder."pangolin/resources/minio_console/domain"}
                        - title: Comms
                          links:
                            - title: Matrix
                              url: https://${config.sops.placeholder."pangolin/resources/element/domain"}
                            - title: Synapse Admin
                              url: https://${config.sops.placeholder."pangolin/resources/synapse_admin/domain"}
                            - title: Mail
                              url: https://${config.sops.placeholder."pangolin/resources/mailadmin/domain"}
                            - title: ezBookkeeping
                              url: https://${config.sops.placeholder."pangolin/resources/ezbookkeeping/domain"}
                            - title: Blog
                              url: https://${config.sops.placeholder."pangolin/resources/whoami/domain"}

                    # SERVICES — Uptime Kuma's status-page heartbeat JSON.
                    # The bootstrap Job creates a status page slugged
                    # "homelab" on first deploy; widget populates after that.
                    - type: custom-api
                      title: Services
                      cache: 1m
                      url: ${kuma}/api/status-page/homelab
                      subrequests:
                        hb:
                          url: ${kuma}/api/status-page/heartbeat/homelab
                      template: |
                        {{ $hb := .Subrequest "hb" }}
                        <div class="cards-grid">
                        {{ range .JSON.Array "publicGroupList" }}
                          {{ range .Array "monitorList" }}
                            {{ $id := .String "id" }}
                            {{ $name := .String "name" }}
                            {{ $statusPath := printf "heartbeatList.%s.-1.status" $id }}
                            {{ $pingPath   := printf "heartbeatList.%s.-1.ping"   $id }}
                            {{ $status := $hb.JSON.Int $statusPath }}
                            {{ $ping   := $hb.JSON.Int $pingPath }}
                            <div class="card flex flex-column">
                              <span>
                                {{ if eq $status 1 }}<span class="color-positive">●</span>{{ else if eq $status 0 }}<span class="color-negative">●</span>{{ else }}<span class="color-paragraph">●</span>{{ end }}
                                {{ $name }}
                              </span>
                              {{ if gt $ping 0 }}<span class="size-h6 color-paragraph">{{ $ping }} ms</span>{{ end }}
                            </div>
                          {{ end }}
                        {{ end }}
                        </div>

                    # NIXPKGS DRIFT — homelab-overkill
                    - type: custom-api
                      title: nixpkgs — homelab-overkill
                      cache: 30m
                      url: https://${config.sops.placeholder."pangolin/resources/gitlab/domain"}/api/v4/projects/bovf%2Fhomelab-overkill/repository/files/flake.lock/raw?ref=main
                      headers:
                        PRIVATE-TOKEN: ''${GITLAB_TOKEN}
                      subrequests:
                        head:
                          url: https://api.github.com/repos/NixOS/nixpkgs/commits/nixos-unstable
                      template: |
                        {{ $head    := .Subrequest "head" }}
                        {{ $pinSha  := .JSON.String "nodes.nixpkgs.locked.rev" }}
                        {{ $pinTs   := .JSON.Float  "nodes.nixpkgs.locked.lastModified" }}
                        {{ $headSha := $head.JSON.String "sha" }}
                        {{ $nowUnix := now.Unix }}
                        {{ $drift   := div (sub (toFloat $nowUnix) $pinTs) 86400.0 }}
                        <div class="flex flex-column gap-5">
                          <div class="flex justify-between"><span>pin</span><span class="color-highlight">{{ slice $pinSha 0 8 }}</span></div>
                          <div class="flex justify-between"><span>head</span><span class="color-highlight">{{ slice $headSha 0 8 }}</span></div>
                          <div class="flex justify-between"><span>drift</span><span>{{ printf "%.0fd" $drift }}</span></div>
                        </div>

                    # NIXPKGS DRIFT — pl-badwater
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
                        {{ $pinTs   := .JSON.Float  "nodes.nixpkgs.locked.lastModified" }}
                        {{ $headSha := $head.JSON.String "sha" }}
                        {{ $nowUnix := now.Unix }}
                        {{ $drift   := div (sub (toFloat $nowUnix) $pinTs) 86400.0 }}
                        <div class="flex flex-column gap-5">
                          <div class="flex justify-between"><span>pin</span><span class="color-highlight">{{ slice $pinSha 0 8 }}</span></div>
                          <div class="flex justify-between"><span>head</span><span class="color-highlight">{{ slice $headSha 0 8 }}</span></div>
                          <div class="flex justify-between"><span>drift</span><span>{{ printf "%.0fd" $drift }}</span></div>
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

                # ── right sidebar ─────────────────────────────────────
                - size: small
                  widgets:
                    - type: bookmarks
                      groups:
                        - title: Infra
                          links:
                            - title: ArgoCD
                              url: https://${config.sops.placeholder."pangolin/resources/argocd/domain"}
                            - title: GitLab
                              url: https://${config.sops.placeholder."pangolin/resources/gitlab/domain"}
                            - title: Grafana
                              url: https://${config.sops.placeholder."pangolin/resources/grafana/domain"}
                            - title: Pangolin
                              url: https://pangolin.dobryops.com

                    # SPEEDTEST — latest result from speedtest-tracker.
                    # Path is `data.<field>` on v1.x of the linuxserver image.
                    - type: custom-api
                      title: Speedtest
                      cache: 5m
                      url: ${spdtest}/api/v1/speedtests/latest
                      template: |
                        <div class="flex flex-column gap-5">
                          <div class="flex justify-between"><span>↓ download</span><span class="size-h4">{{ printf "%.0f Mbps" (.JSON.Float "data.download") }}</span></div>
                          <div class="flex justify-between"><span>↑ upload</span><span class="size-h4">{{ printf "%.0f Mbps" (.JSON.Float "data.upload") }}</span></div>
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
                - size: small
                  widgets:
                    - type: bookmarks
                      groups:
                        - title: Library
                          links:
                            - title: Jellyfin
                              url: https://${config.sops.placeholder."pangolin/resources/jellyfin/domain"}
                            - title: Jellyseerr
                              url: https://${config.sops.placeholder."pangolin/resources/jellyseerr/domain"}
                - size: full
                  widgets:
                    - type: bookmarks
                      groups:
                        - title: Manage
                          links:
                            - title: Sonarr
                              url: https://${config.sops.placeholder."pangolin/resources/sonarr/domain"}
                            - title: Radarr
                              url: https://${config.sops.placeholder."pangolin/resources/radarr/domain"}
                            - title: Sportarr
                              url: https://${config.sops.placeholder."pangolin/resources/sportarr/domain"}
                            - title: Bazarr
                              url: https://${config.sops.placeholder."pangolin/resources/bazarr/domain"}
                            - title: Prowlarr
                              url: https://${config.sops.placeholder."pangolin/resources/prowlarr/domain"}
                - size: small
                  widgets:
                    - type: bookmarks
                      groups:
                        - title: Queues
                          links:
                            - title: qBittorrent
                              url: https://${config.sops.placeholder."pangolin/resources/qbittorrent/domain"}
                            - title: NZBGet
                              url: https://${config.sops.placeholder."pangolin/resources/nzbget/domain"}

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
                            - title: Matrix
                              url: https://${config.sops.placeholder."pangolin/resources/element/domain"}
                            - title: Grafana
                              url: https://${config.sops.placeholder."pangolin/resources/grafana/domain"}
                            - title: GitLab
                              url: https://${config.sops.placeholder."pangolin/resources/gitlab/domain"}
                    - type: custom-api
                      title: Engineer CPU
                      cache: 30s
                      url: ${promQuery "(1-avg(rate(node_cpu_seconds_total%7Binstance=%22192.0.2.10:9100%22,mode=%22idle%22%7D%5B5m%5D)))*100"}
                      template: |
                        <p class="size-h3">CPU {{ printf "%.0f" (.JSON.Float "data.result.0.value.1") }}%</p>
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
    '';
    path  = "/var/lib/rancher/k3s/server/manifests/glance-config.yaml";
    owner = "root";
    group = "root";
    mode  = "0644";
  };
}
