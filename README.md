<div align="center">

<pre>
██████╗  ██████╗ ██████╗ ██████╗ ██╗   ██╗ ██████╗ ██████╗ ███████╗
██╔══██╗██╔═══██╗██╔══██╗██╔══██╗╚██╗ ██╔╝██╔═══██╗██╔══██╗██╔════╝
██║  ██║██║   ██║██████╔╝██████╔╝ ╚████╔╝ ██║   ██║██████╔╝███████╗
██║  ██║██║   ██║██╔══██╗██╔══██╗  ╚██╔╝  ██║   ██║██╔═══╝ ╚════██║
██████╔╝╚██████╔╝██████╔╝██║  ██║   ██║   ╚██████╔╝██║     ███████║
╚═════╝  ╚═════╝ ╚═════╝ ╚═╝  ╚═╝   ╚═╝    ╚═════╝ ╚═╝     ╚══════╝
</pre>

**A declarative, reproducible home infrastructure stack.**  
*Kubernetes · NixOS · Encrypted Secrets · Zero Exposed Ports*

[![NixOS](https://img.shields.io/badge/NixOS-5277C3?style=for-the-badge&logo=nixos&logoColor=white)](https://nixos.org)
[![Kubernetes](https://img.shields.io/badge/Kubernetes-326CE5?style=for-the-badge&logo=kubernetes&logoColor=white)](https://kubernetes.io)
[![SOPS](https://img.shields.io/badge/SOPS-FFA500?style=for-the-badge&logo=mozilla&logoColor=white)](https://github.com/mozilla/sops)
[![k3s](https://img.shields.io/badge/k3s-FFC61C?style=for-the-badge&logo=k3s&logoColor=black)](https://k3s.io)
[![Helm](https://img.shields.io/badge/Helm-0F1689?style=for-the-badge&logo=helm&logoColor=white)](https://helm.sh)

*Made with coffee and love from Sofia, Bulgaria*

</div>

---

## What This Is

A self-hosted platform built **entirely from version-controlled configs**. Everything - infrastructure, applications, databases, secrets, and tunnels - is defined in code and reproducible from scratch.

> Uses **Nix flakes** to manage NixOS + k3s + Helm charts, **SOPS** for secure secret storage, and **Pangolin** for private network access.

---

## Services

<div align="center">

| Service           | Purpose                                              | Status   |
|-------------------|------------------------------------------------------|:--------:|
| GitLab            | Git, CI/CD, container registry                       | Active   |
| ArgoCD            | GitOps                                               | Active   |
| Keel              | Auto-rollout on `:latest` digest change              | Active   |
| MinIO             | S3 object storage                                    | Active   |
| PostgreSQL        | SQL database                                         | Active   |
| Jellyfin          | Media streaming                                      | Active   |
| Sonarr            | TV show automation                                   | Active   |
| Radarr            | Movie automation                                     | Active   |
| Prowlarr          | Indexer management                                   | Active   |
| Bazarr            | Subtitle automation                                  | Active   |
| Jellyseerr        | Media request portal                                 | Active   |
| qBittorrent       | Torrent client                                       | Active   |
| NZBGet            | Usenet client                                        | Active   |
| Sportarr          | Sports event automation (*arr-style)                 | Active   |
| pgAdmin           | Postgres web admin                                   | Active   |
| Grafana           | Metrics, logs, dashboards                            | Active   |
| Prometheus        | Metrics store                                        | Active   |
| Alertmanager      | Email alerts (Gmail SMTP)                            | Active   |
| Loki + Alloy      | Log aggregation + collection (S3 → MinIO)            | Active   |
| version-checker   | Image drift metrics                                  | Active   |
| nova              | Helm chart drift (weekly CronJob)                    | Active   |
| intel-gpu-exporter| Intel iGPU utilisation metrics                       | Active   |
| intel-gpu-plugin  | Exposes the Intel iGPU to pods (QuickSync transcode) | Active   |
| local-path-du     | Per-PVC disk usage exporter (du-based)               | Active   |
| Pi-hole           | DNS / ad blocking + auto-aggregated LAN A records    | Active*  |
| whoami            | Personal blog (auto-deploys on each main commit)     | Active   |
| ezBookkeeping     | Personal finance / bookkeeping (Postgres-backed)     | Active   |
| Matrix            | Synapse + Element Web + synapse-admin (fed-whitelist)| Active   |
| Element Call      | LiveKit SFU + lk-jwt — Matrix RTC (runs on VPS)      | Active   |
| Homarr            | Self-hosted homepage / launcher (`home.dobryops.com`)| Active   |
| grafana-image-renderer | Headless-chromium PNG renderer for Grafana panels | Active   |
| Squid             | HTTP forward proxy (LAN egress)                      | Active   |
| ncps              | Nix binary cache proxy (caches `cache.nixos.org`)    | Active   |
| Hale (Saxton)     | Matrix-connected hermes-agent: media-ordering skills, restricted k8s observer SA, runs as system user `hale` on engineer | Active |
| MS Researcher     | Matrix-connected hermes-agent for MS research KB, RSS enrichment, PubMed/CrossRef/SearXNG verification, and Monday digest | Active |
| pangolin-kwg      | Host-side kernel WG client (engineer ↔ pangolin VPS) | Active   |
| newt-cicd         | In-cluster userspace WG for CI-managed gitops flow   | Active   |
| MetalLB           | L2-mode LoadBalancer for per-service LAN IPs         | Active   |
| cert-manager      | Wildcard `*.dobryops.com` via Let's Encrypt DNS-01   | Active   |

</div>

> \* Pi-hole serves DNS for the cluster's domains via per-workload `local-dns.nix` declarations aggregated into `FTLCONF_dns_hosts`. Setting it as the LAN's upstream DNS is a router-side change.

Mail hosting for `dobryops.com` is intentionally external via Proton Mail; this cluster does not run an SMTP/IMAP mail server.

### MS Researcher Agent

`services.ms-researcher` runs a dedicated Hermes Matrix bot on `engineer` for Multiple Sclerosis research tracking. It maintains a mutable Logseq-style KB at `/var/lib/ms-researcher/kb` and exposes it under `/home/ms-researcher/kb` for the agent.

What it does:
- Watches curated MS research/news/trial/practical-living RSS feeds every 6 hours.
- Scores source credibility and filters out low-trust, miracle-cure, product-pitch, or unverified claims.
- Verifies research through PubMed, CrossRef, ClinicalTrials.gov, SearXNG, and official/recognized MS sources before writing KB pages.
- Writes citation-grounded pages, run reports, journals, and weekly reports under the KB tree.
- Publishes a reader-friendly Monday morning "This week in MS" digest at 08:00 Europe/Sofia.
- Exposes the KB as a read-only Logseq-style web view at `ms-kb.dobryops.com` via the `knowledgebase` namespace.
- Cleans generated RSS raw cache weekly after the digest while preserving manual raw ingests and the RSS seen ledger.
- Syncs the KB to GitLab every 10 minutes when `/var/lib/ms-researcher/kb` has been initialized as a git repo.

Operational notes:
- Codex subscription auth is mutable user state. Authenticate with:
  `sudo -u ms-researcher -H /run/current-system/sw/bin/hermes auth add openai-codex --type oauth --no-browser`
- The KB git repo is initialized manually as `ms-researcher`; Nix wires git/ssh/sops credentials but does not clone over mutable state.
- The web viewer pulls `git@gitlab.dobryops.com:knowledge-base/ms-researcher-kb.git` over SSH every few minutes and republishes the static Logseq view when the repo changes.
- The viewer redirects the empty Logseq landing route to `Start Here`, which the agent keeps updated as the curated KB front door.
- The KB uses a V2 date/type layout: canonical content in `content/{studies,trials,practical,reports,queries}/...`, journals in `journals/YYYY/MM/YYYY_MM_DD.md`, and navigation pages in `pages/`.
- The agent's `kb-maintain` skill self-heals legacy flat files into that layout and refreshes `Start Here`, `Index`, and sub-index pages.
- The viewer also exposes raw KB file-tree browsing at `/kb/`; `.git` paths are blocked.
- The viewer is read-only; editing remains through the agent, GitLab, or local Logseq.
- `koth-dm` is disabled on `engineer`; `hale` is unchanged.

---

## Quick Start

### Prerequisites

- NixOS (or Linux with Nix)
- Basic familiarity with Nix and Kubernetes
- A VPS running Pangolin (this flake's `pangolin-kwg` site connects via kernel WireGuard)

### Setup

**1. Clone the repo**
```bash
git clone https://github.com/bovf/homelab-overkill.git
cd homelab-overkill
```

**2. Pull secrets from Bitwarden**
```bash
nix run .#secrets -- pull
nix run .#secrets -- init
nix run .#secrets -- bootstrap <node>
```

**3. Install on your node**
```bash
nix run .#deploy -- install engineer-local
```

**4. Update an existing cluster**
```bash
nix run .#deploy -- update engineer-local
```

**5. Format/check Nix changes**
```bash
nix run .#fmt --                 # format all tracked *.nix files
nix run .#fmt -- --check         # check all tracked *.nix files
nix run .#fmt -- --check flake.nix nix/shells/default.nix
```

The dev shell also auto-installs a pre-commit hook that checks staged `.nix`
files with `nix run .#fmt -- --check`.

**6. Bootstrap kubeconfig for local k9s/kubectl access**
```bash
eval $(nix run .#kubeconfig -- engineer-local)
kubectl get nodes
k9s
```

---

## How It Works

```
┌─────────────┐    ┌──────────┐    ┌───────────┐    ┌──────────────┐
│  Nix Flakes │───>│   SOPS   │───>│    k3s    │───>│     Helm     │
│  (IaC defn) │    │(encrypted│    │(k8s layer)│    │ (app deploy) │
└─────────────┘    │ secrets) │    └───────────┘    └──────────────┘
                   └──────────┘           │
                  ┌───────────────────────┴─────────────────────┐
                  │                                             │
                  v                                             v
       ┌────────────────────────────┐         ┌─────────────────────────┐
       │ Pangolin (off-LAN access)  │         │ MetalLB (LAN-direct)    │
       │ • pangolin-kwg site        │         │ • Per-service LAN IPs   │
       │   (kernel WG, host-side)   │         │ • Pi-hole local DNS     │
       │ • olm clients              │         └─────────────────────────┘
       │   (WG VPN for Mac/iOS)     │
       │ • newt-cicd (CI gitops)    │
       └────────────────────────────┘
```

| Step | Component     | Role                                                         |
|------|---------------|--------------------------------------------------------------|
| 1    | Nix Flakes    | Describe the entire infrastructure as code                   |
| 2    | SOPS          | Encrypt secrets before version control                       |
| 3    | k3s           | Lightweight Kubernetes runtime                               |
| 4    | Helm          | Application packaging + deploy                               |
| 5    | pangolin-kwg  | Host-side kernel-WireGuard tunnel to the pangolin VPS        |
| 6    | Olm clients   | WG VPN replacing Tailscale; direct access to tunnel IPs      |
| 7    | MetalLB       | L2 LoadBalancer for per-service LAN IPs                      |
| 8    | Pi-hole       | Cluster DNS upstream; LAN A records + DoH adlist             |
| 9    | cert-manager  | Wildcard `*.dobryops.com` via Let's Encrypt DNS-01           |
| 10   | Reloader      | Rolling-restarts pods when watched ConfigMaps/Secrets change |
| 11   | Keel          | Rolls deployments on `:latest` digest change                 |
| 12   | GitOps        | Edit → commit → deploy. Always reproducible                  |

---

## Security Model

For the known places where setup or app configuration is intentionally not fully
Nix-declarative, see `notes/not-declerative-functionality.md`.

> **No sensitive data exists in plain text in this repository.**  
> Every domain name, credential, email, and API key is encrypted at rest via SOPS and injected at runtime.

### How Secrets Reach Workloads

```
secrets/secrets.yaml  (SOPS encrypted)
         |
         v  sops-nix decrypts on nixos-rebuild switch
         |
/var/lib/rancher/k3s/server/manifests/   (rendered YAML with substituted values)
         |
         v  k3s auto-applies manifests
         |
  K8s Secrets / ConfigMaps / HelmCharts
         |
         v  Pods mount as volumes or env vars
```

### Pangolin Blueprint System

Each workload self-registers via a `pangolin-blueprint.nix` file. On `nixos-rebuild switch`, `pangolin-kwg-blueprint-sync.service` renders the full org blueprint and PUTs it to Pangolin's REST API — no manual UI changes, no in-cluster aggregator pod for engineer-side resources.

The cicd-gitops site keeps the legacy ConfigMap aggregator (cronjob in `cicd/apps/newt/`) because its blueprint is CI-managed, not nix-managed.

Supports:
- **HTTP resources** — SSO, custom rules, headers
- **Raw TCP/UDP resources** — SSH, k8s API, gitlab-shell, etc.

### sops-nix Symlink Patch

k3s detects manifest changes via `mtime + SHA256` on the file inode - symlink `mtime` never changes when target content changes. A patch to `sops-install-secrets` forces symlinks to be **recreated on every activation**, giving them a fresh `mtime` so k3s re-applies updated manifests within **~15 seconds**.

### Git Hooks and Formatting

The dev shell auto-installs two Nix-store-managed hooks when entering `nix-shell`
(or any shell that evaluates `.#devShells.<system>.default`). Existing manual,
non-symlink hooks are left untouched.

- **`pre-commit`** — checks staged `.nix` files with `nix run .#fmt -- --check <files>`. It fails fast if Alejandra would reformat them.
- **`pre-push`** — runs `gitleaks git . --redact --exit-code 1` against the full history with `.gitleaksignore` allowlist applied.

Formatting commands:

```bash
nix run .#fmt --                 # format all tracked *.nix files
nix run .#fmt -- --check         # check all tracked *.nix files
nix run .#fmt -- file1.nix ...   # format selected files
```

`alejandra` is also in the dev shell for ad-hoc use, but `nix run .#fmt` is the
repo-native entry point and the one used by the hook.

### Secret Scanning

`nix run .#scan` runs both `gitleaks` and `trufflehog` (full scan — no `--only-verified` suppression). The workflow is strict: every finding either gets rotated (real secret) or pinned with a written reason in a per-finding allowlist file.

- **`.gitleaksignore`** — native gitleaks per-finding fingerprints; `# Reason: ...` comment on the line ABOVE each fingerprint (gitleaks doesn't support inline comments)
- **`.trufflehog-allowlist`** — custom file consumed by the scan app's trufflehog wrapper; same `# Reason:` + fingerprint convention. Fingerprint format: `<DetectorName>:<commit-sha>:<file>:<line>`

No categorical suppression — no path-based allowlists, no regex allowlists. Pin a finding in commit A line 286, and a similar-looking real secret in commit B line 12 still fires. Each pin is a deliberate, reviewable line with a written reason. Both scanners are added to the devShell `packages` so they're on `$PATH` inside `nix-shell` for ad-hoc use too.

---

## Repository Structure

```
.
├── flake.nix                  # Entry point + sops-nix patch overlay + uv2nix
├── flake.lock
├── .sops.yaml
├── .gitleaksignore            # gitleaks per-finding allowlist (fingerprints + reasons)
├── .trufflehog-allowlist      # trufflehog per-finding allowlist (fingerprints + reasons)
├── README.md
├── notes/
│   └── not-declerative-functionality.md  # Inventory/runbook for imperative state and setup
│
├── nix/                       # Nix apps and tooling
│   ├── apps/
│   │   ├── deploy.nix         # nixos-rebuild-ng based deploy script
│   │   ├── kubeconfig.nix     # Kubeconfig bootstrap for local k9s/kubectl
│   │   ├── secrets.nix        # Bitwarden secrets management
│   │   ├── fmt.nix            # `nix run .#fmt` — Alejandra formatter/check app
│   │   ├── scan.nix           # `nix run .#scan` — gitleaks + trufflehog wrapper
│   │   └── utilities.nix      # Node status checks
│   ├── patches/
│   │   └── sops-always-recreate-symlink.patch
│   └── shells/                # devShell + auto-installs fmt pre-commit and gitleaks pre-push hooks
│
├── nodes/                     # NixOS machines
│   ├── engineer/              # Main node config
│   │   ├── default.nix
│   │   ├── hardware.nix
│   │   ├── disko.nix
│   │   ├── services.nix
│   │   ├── pangolin-kwg.nix         # kwg client + blueprint-sync wiring
│   │   ├── pangolin-resources.nix   # Host-level TCP resources (ssh, k8s API)
│   │   └── metallb.nix              # MetalLB pool config
│   └── sentry-level-01/       # Future worker node (scaffolded, disabled)
│
├── infrastructure/            # Host-level cluster + tunnel modules
│   ├── k3s/                   # Cluster config (server + agent roles)
│   │   ├── cluster.nix
│   │   ├── networking.nix
│   │   ├── manifest-cleanup.nix     # Prunes orphaned manifest symlinks
│   │   ├── server/
│   │   └── worker/
│   ├── metallb/               # L2 LoadBalancer (helm + IPAddressPool + L2Advertisement)
│   └── pangolin-kwg/          # Host-side kernel WireGuard + REST blueprint sync
│
├── workloads/                 # Kubernetes namespaces & apps
│   ├── default.nix
│   ├── lib/                   # lan-services + pangolin-blueprint generators
│   └── namespace/
│       ├── kube-system/       # traefik, node-feature-discovery
│       ├── intel-device-plugins/  # Intel GPU device plugin + operator
│       ├── knowledgebase/     # MS Researcher KB read-only Logseq published web UI
│       ├── database/          # postgresql, minio (+ loki bucket init), pgadmin
│       ├── cicd/              # gitlab, argocd, reloader, keel, newt
│       ├── media/             # jellyfin, sonarr, radarr, prowlarr, bazarr,
│       │                      # jellyseerr, qbittorrent, nzbget, sportarr
│       ├── monitoring/        # kube-prometheus-stack, loki, alloy,
│       │                      # grafana-image-renderer, version-checker,
│       │                      # nova, intel-gpu-exporter,
│       │                      # local-path-du-exporter, grafana-dashboards
│       │                      #   (incl. node-overview desktop +
│       │                      #    node-overview-mobile-{s,m,l})
│       ├── cert-manager/      # letsencrypt cluster issuer
│       ├── dns/               # pihole
│       ├── finance/           # ezbookkeeping
│       ├── matrix/            # synapse, element, synapse-admin
│       ├── homarr/            # homepage / launcher (home.dobryops.com)
│       ├── proxy/             # squid, ncps
│       └── blog/              # whoami personal blog
│
├── common/                    # Shared NixOS modules
│   ├── base.nix, services.nix, users.nix, default.nix
│   ├── hale.nix               # Saxton Hale: system user, restricted k8s observer SA,
│   │                          # hermes-agent systemd unit (built via uv2nix overlay),
│   │                          # matrix gateway + bootstrap Job, skill auto-discovery
│   ├── hale-skills/           # SKILL.md files auto-symlinked into ~/.hermes/skills/
│   │                          # (arr-search, arr-library, arr-releases, arr-grab,
│   │                          # arr-add-to-library, arr-search-mobile, qbit-list,
│   │                          # nzbget-list, media-status)
│   ├── hale-soul.md           # Saxton Hale persona / system prompt
│   ├── hale.png               # Bot's matrix avatar (uploaded by the bootstrap Job)
│   ├── ms-researcher.nix      # MS research Hermes agent, Matrix bootstrap, KB git sync,
│   │                          # RSS cron jobs, PubMed/CrossRef/SearXNG MCP wiring
│   ├── ms-researcher-skills/  # KB research, ingest, journal, RSS watch, RSS cleanup skills
│   └── ms-researcher-cron/    # 6-hour RSS enrichment, Monday digest, RSS raw cleanup
│
├── secrets/                   # SOPS-encrypted secrets
│   ├── secrets.yaml           # Encrypted values (age)
│   └── default.nix            # sops.secrets declarations
│
└── scripts/                   # One-shot ops helpers
    └── homarr-seed-boards.sh  # Reseeds Homarr boards via SQLite
```

---

## Workload Pattern

Every app follows a consistent, predictable structure:

```
workloads/namespace/<ns>/apps/<app>/
├── default.nix              # imports list
├── helm.nix                 # HelmChart manifest  (via sops.templates)
├── middleware.nix           # Traefik Middleware  (via sops.templates)
├── secret.nix               # K8s Secrets with injected credentials
├── pangolin-blueprint.nix   # (optional) Registers app as a Pangolin resource
├── local-dns.nix            # (optional) Pi-hole LAN A record
└── external-services.nix    # (optional) Sibling Service for charts whose
                             #   `service.externalIPs` doesn't propagate
```

> All `helm.nix` and `middleware.nix` files use `sops.templates` - domain names and credentials are **never present in git**.

### Three access paths

A resource is reachable via one or more of:

| Path | Hostname | Goes through | Used when |
|---|---|---|---|
| **Pangolin public** | `*.dobryops.com` | Public IP → pangolin VPS → kwg tunnel → backend | Off-LAN, no VPN. SSO-gated for HTTP. |
| **Pangolin client (olm)** | Tunnel IP (`100.89.128.x`) or DNS | Mac/iOS olm WG → pangolin VPS → kwg tunnel → backend | Off-LAN with VPN installed. No public ports needed. |
| **LAN-direct** | LAN IP (`192.168.2.x`), resolved via Pi-hole | MetalLB L2 announce → traefik → backend | On-LAN. No round-trip via the VPS. |

`viaKernelWg = true` (the default for every workload now) routes the resource through the host-side `pangolin-kwg` tunnel — kube-proxy externalIPs on each Service catches the matching `100.89.128.16:<port>` and DNATs to the backend pod. The blueprint sync service PUTs the rendered YAML to Pangolin's REST API on every `nixos-rebuild switch`, so resources rebind without manual UI work.

### Local DNS aggregation

Each workload's `local-dns.nix` declares one `{ host, ip }` entry under `workloads.localDnsRecords`. Pi-hole's helm chart collapses the attrset into `FTLCONF_dns_hosts`, which v6 reads into `dns.hosts[]` (UI-visible). Adding a new LAN-resolvable service is one file in the owning workload — no central registry edit.

### DNS topology

Pi-hole is the single resolver for both LAN clients and cluster pods:

```
LAN clients  ───┐
                ├──> 192.168.2.2 (pihole) ──> 1.1.1.1 (Cloudflare upstream)
Cluster pods ───┤
                └──> 10.43.0.10 (CoreDNS) ──> 192.168.2.2 (pihole)
```

`networking.nameservers = [ "192.168.2.2" "1.1.1.1" ]` on engineer makes the host point at pihole; CoreDNS inherits the node's `/etc/resolv.conf` via `dnsPolicy: Default`, so every pod's external DNS gets logged in pihole too. `1.1.1.1` is the failover if pihole is down. Pi-hole's own pod uses `8.8.8.8/8.8.4.4` via `podDnsConfig` to avoid the chicken-and-egg.

### TLS

Two terminators handle TLS, depending on the access path:

- **Public path** — Cloudflare-fronted pangolin VPS terminates TLS at the edge with its own `*.dobryops.com` cert. Tunnel-internal traffic to engineer is plain HTTP. No cluster cert needed.
- **LAN-direct path** — cert-manager issues a wildcard `*.dobryops.com` cert from Let's Encrypt via the **DNS-01** solver against the Cloudflare zone (the only way LE issues wildcards). Traefik picks it up as `tlsStore.default.defaultCertificate`, so every LAN-side HTTPS request to `*.dobryops.com` is served with a publicly-trusted cert — no per-device root-CA install.

---


<div align="center">
*Keep it simple. Keep it declarative. Keep secrets secret.*

**Star this repo if it sparked ideas for your own homelab.**

</div>
