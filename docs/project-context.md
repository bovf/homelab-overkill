# Project map

[README](../README.md) · [Operations](operations.md) · [Development](development.md)

This describes the checked-in configuration. Evaluate the current checkout when
flags matter; inspect the hosts separately when deployment or health matters.

## Hosts and deployment flow

[`flake.nix`](../flake.nix) defines two x86_64-linux hosts:

- **Engineer:** imports its node module, `common`, `infrastructure`, `secrets`,
  `workloads`, Home Manager and the Hermes overlay. It is the only declared k3s
  node. `sentry-level-01` is commented metadata, not an implemented worker.
- **Pangolin:** imports only its node modules plus Disko/SOPS. Pangolin, Gerbil,
  Traefik, LiveKit, lk-jwt and fail2ban are native NixOS services. Docker is also
  enabled, but the edge stack is not deployed through Docker Compose.

```text
flake.nix + flake.lock
├── Engineer NixOS
│   ├── services.k3s.manifests → non-secret Kubernetes objects
│   ├── sops.templates        → runtime-substituted manifests
│   │                              ↓
│   │                 k3s Addons / Helm controller
│   └── systemd services: WireGuard, blueprint sync, Hale
└── Pangolin NixOS → native edge services + runtime secret files
```

Most charts are `helm.cattle.io/v1` HelmChart objects in `kube-system`, targeting
an application namespace. Bundled Traefik/CoreDNS use HelmChartConfig overrides.
PostgreSQL, bootstrap Jobs, exporters and several proxy services use raw objects.
Import order does not establish service readiness; bootstrap Jobs wait for their
dependencies. ArgoCD manages a separate GitOps surface, not these Nix imports.

Two lifecycle traps:

- `workloads.enable` and `infrastructure.enable` are **not reliable master off
  switches**; many declarations are unconditional.
- [Manifest cleanup](../infrastructure/k3s/manifest-cleanup.nix) removes orphaned
  symlinks, not deployed objects or data. Removing an import is not an uninstall.

## Workloads

The [namespace entrypoint](../workloads/namespace/default.nix) explicitly imports
these directories. Each namespace's `default.nix` lists its app imports.

| Namespace | App modules |
| --- | --- |
| [blog](../workloads/namespace/blog/default.nix) | whoami |
| [cert-manager](../workloads/namespace/cert-manager/default.nix) | cert-manager |
| [cicd](../workloads/namespace/cicd/default.nix) | GitLab, GitLab Nix runner, ArgoCD, Reloader, Keel, Newt |
| [dashboard](../workloads/namespace/dashboard/default.nix) | Glance, SearXNG |
| [database](../workloads/namespace/database/default.nix) | PostgreSQL, MinIO, pgAdmin |
| [dns](../workloads/namespace/dns/default.nix) | Pi-hole |
| [finance](../workloads/namespace/finance/default.nix) | ezBookkeeping |
| [health](../workloads/namespace/health/default.nix) | SparkyFitness |
| [homarr](../workloads/namespace/homarr/default.nix) | Homarr |
| [intel-device-plugins](../workloads/namespace/intel-device-plugins/default.nix) | GPU plugin, operator |
| [knowledgebase](../workloads/namespace/knowledgebase/default.nix) | MS Researcher KB viewer |
| [kube-system](../workloads/namespace/kube-system/default.nix) | CoreDNS, Traefik, Node Feature Discovery |
| [matrix](../workloads/namespace/matrix/default.nix) | Synapse, Element, synapse-admin |
| [media](../workloads/namespace/media/default.nix) | Bazarr, Jellyfin, Jellyseerr/Seerr (`jellyseer/`), Prowlarr, qBittorrent, Radarr, Sonarr, NZBGet, RomM, Sportarr |
| [monitoring](../workloads/namespace/monitoring/default.nix) | kube-prometheus-stack, dashboards, Loki, Alloy, renderer, GPU/PVC exporters, version-checker, Nova, Kuma, speedtest-tracker |
| [proxy](../workloads/namespace/proxy/default.nix) | Attic, ncps, Squid |
| [surveillance](../workloads/namespace/surveillance/default.nix) | go2rtc |

MetalLB is under `infrastructure`; Hale's observer creates the additional
`hermes` namespace. Prometheus, Grafana and Alertmanager belong to
`kube-prometheus-stack`, not separate app directories. Mail hosting is external
(Proton Mail); the cluster does not host SMTP/IMAP mailboxes.

## Network paths

| Path | Route | Source |
| --- | --- | --- |
| Public HTTP/TCP | VPS → Basic WireGuard → `100.89.128.16:<service-port>` → backend | [Blueprint sync](../infrastructure/pangolin-kwg/blueprint.nix) |
| LAN HTTP | Pi-hole A record → dedicated MetalLB IP → Traefik Host routing → backend | [LAN Service generator](../workloads/lib/lan-services.nix) |
| Olm VPN | Client → VPS VPN → routed tunnel resources | [VPS firewall](../nodes/pangolin/firewall.nix) |
| Matrix calls | HTTPS signaling on VPS; direct media TCP 7881 / UDP 50000 | [LiveKit configuration](../nodes/pangolin/element-call.nix) |

All currently declared Pangolin resources set `viaKernelWg = true`; its option
default is false. The renderer rewrites hostnames to Engineer's tunnel IP, **not
ports**. Keep each `(externalIP, protocol, Service port)` unique. Some charts need
sibling Services because their values do not propagate `externalIPs`.

Host SSH and the k3s API listen directly; Heavy SSH uses a DNAT rule. Engineer
and Heavy public SSH resources default to disabled and are reset by blueprint
sync. See [tunnel setup](../nodes/engineer/bootstrapping.md).

### Exposure and authentication

`pangolinResources.<name>.enabled` controls **public exposure**, not deployment.
The LAN generator creates a Service whenever `lanIP` is set, even if the public
resource is disabled. SSO applies per HTTP resource; raw TCP relies on the
backend protocol's authentication. LAN traffic does not inherit Pangolin SSO.
The [per-app blueprints](../workloads/namespace/) are the exposure source of truth.

Host-side sync PUTs the **whole organization's blueprint** on activation; its
activation restart is best-effort. Check the systemd result after deploying.
The [CI Newt connector](../workloads/namespace/cicd/apps/newt/default.nix) has a
separate hourly labeled-ConfigMap aggregation path for CI-managed services.

### DNS and TLS

- MetalLB's L2 pool is `192.168.2.0/24`. Router/client routing is external setup.
- [Pi-hole](../workloads/namespace/dns/apps/pihole/helm.nix) listens for DNS at
  `192.168.2.2` and aggregates each app's `local-dns.nix` record.
- Host DNS prefers Pi-hole. CoreDNS has an explicit `dobryops.com` block with
  sequential Pi-hole/Cloudflare/Google fallback. A fallback can return public
  rather than LAN addresses. Pi-hole uses independent DNS to avoid a loop.
- Public TLS terminates at VPS Traefik with HTTP-01 ACME. LAN Traefik uses
  cert-manager's Cloudflare DNS-01 wildcard certificate. Certificate readiness
  and client DNS configuration require live checks.

## Important dependencies and compatibility code

- [PostgreSQL](../workloads/namespace/database/apps/postgresql/default.nix) serves
  GitLab, Synapse, ezBookkeeping, SparkyFitness and RomM. MinIO serves GitLab and
  Loki. Their init Jobs provision accounts/buckets; they are not universal
  credential-rotation controllers.
- GitLab uses a [separate Nix-managed Redis Deployment](../workloads/namespace/cicd/apps/gitlab/redis.nix)
  with a persistent local-path claim and the generated GitLab Redis Secret.
  Native HTTP MCP uses GitLab OAuth, not Pangolin SSO. See
  [GitLab and Redis operations](operations.md#gitlab-and-redis).
- Media apps share `media-pvc`. Jellyfin uses the Intel device plugin and host
  graphics libraries. qBittorrent shares Gluetun's VPN network namespace and
  synchronizes ProtonVPN's forwarded port.
- [Attic](../workloads/namespace/proxy/apps/attic-cache/default.nix) hosts the public
  `badwater` Nix cache. It runs the Nix-packaged binary with a read-only host
  store mount; ncps separately proxies cache.nixos.org. Attic's app-owned
  post-sync API repair clears stale disabled-health state on its WG target.
- Preserve the [SOPS symlink patch](../nix/patches/sops-always-recreate-symlink.patch)
  when updating SOPS: k3s must notice refreshed rendered manifests.
- Preserve the tunnel's MTU/MSS/reverse-path settings. The old
  `gerbil-basic-wg-reconcile` workaround is gone; current Pangolin handles Basic
  WG peers upstream. VPS Traefik loads pinned Badger locally and skips backend
  TLS certificate verification; do not mistake that for end-to-end verified TLS.

## Agents and research KB

Enabled state lives in [Engineer's node module](../nodes/engineer/default.nix).

| Component | Current declaration | State / responsibility |
| --- | --- | --- |
| [Hale](../common/hale.nix) | Enabled | Matrix gateway; Kubernetes get/list/watch without Secrets; media API actions are confirmation-gated by skills |
| [MS Researcher](../common/ms-researcher.nix) | Disabled, including cron/MCP/Git sync | Mutable KB at `/var/lib/ms-researcher/kb`; preserved research workflow |
| [KotH DM](../common/koth-dm.nix) | Disabled | Preserved campaign skills and character/dice/turn MCP tools |
| [KB viewer](../workloads/namespace/knowledgebase/apps/ms-researcher-kb/helm.nix) | Independently imported | Polls GitLab `main` every 300s; publishes Logseq and raw `/kb/` files |

Hermes is built by the flake's uv2nix overlay. Personas/skills are versioned;
OAuth, sessions, campaign records and user profiles are mutable. The viewer
publishes the full KB except `.git`; HTTP readiness does not prove fresh content.
Check `.published-head`, `.published-at` and publisher logs. Review the
[disabled-agent blockers](housekeeping-audit.md#before-re-enabling-agents) before
reviving a writer; do not put private material in the published KB.
