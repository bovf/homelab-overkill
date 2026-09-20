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
*Kubernetes · NixOS · Encrypted Secrets · WireGuard-connected Public Edge*

[![NixOS](https://img.shields.io/badge/NixOS-5277C3?style=for-the-badge&logo=nixos&logoColor=white)](https://nixos.org)
[![Kubernetes](https://img.shields.io/badge/Kubernetes-326CE5?style=for-the-badge&logo=kubernetes&logoColor=white)](https://kubernetes.io)
[![SOPS](https://img.shields.io/badge/SOPS-FFA500?style=for-the-badge&logo=mozilla&logoColor=white)](https://github.com/mozilla/sops)
[![k3s](https://img.shields.io/badge/k3s-FFC61C?style=for-the-badge&logo=k3s&logoColor=black)](https://k3s.io)
[![Helm](https://img.shields.io/badge/Helm-0F1689?style=for-the-badge&logo=helm&logoColor=white)](https://helm.sh)

*Made with coffee and love from Sofia, Bulgaria*

</div>

---

## What This Is

A self-hosted platform with **version-controlled infrastructure and application configuration**. Nix describes the hosts, workloads, secret wiring, and tunnels; databases, application data, OAuth sessions, and some initial provisioning remain mutable and need separate recovery procedures.

> Uses **Nix flakes** to manage NixOS + k3s + Helm charts, **SOPS** for secure secret storage, and **Pangolin** for public-edge and VPN access.

Start with the [project knowledge base](docs/project-context.md) for the source map, operational boundaries, validation commands, and documentation maintenance checklist. See [engineer bootstrapping](nodes/engineer/bootstrapping.md) for initial WireGuard site setup. The [housekeeping audit](docs/housekeeping-audit.md) groups open issues by topic, with impacts, proposed fixes, and verification steps.

---

## Services

<div align="center">

| Service | Purpose | Configuration |
|---------|---------|:-------------:|
| GitLab + Nix runner | Git, CI/CD, container registry, cache builds | Declared |
| ArgoCD | GitOps for separately managed applications | Declared |
| Keel | Opt-in image rollouts (including whoami's `latest` tag) | Declared |
| Reloader | Restart workloads watching changed Secrets/ConfigMaps | Declared |
| MinIO | S3 object storage | Declared |
| PostgreSQL | SQL database | Declared |
| Jellyfin | Media streaming | Declared |
| Sonarr | TV show automation | Declared |
| Radarr | Movie automation | Declared |
| Prowlarr | Indexer management | Declared |
| Bazarr | Subtitle automation | Declared |
| Jellyseerr | Media request portal | Declared |
| qBittorrent | Torrent client | Declared |
| NZBGet | Usenet client | Declared |
| Sportarr | Sports event automation | Declared |
| RomM | ROM library management | Declared |
| pgAdmin | Postgres web admin | Declared |
| Grafana | Metrics, logs, dashboards | Declared |
| Prometheus | Metrics store | Declared |
| Alertmanager | Email alerts (Gmail SMTP) | Declared |
| Loki + Alloy | Log aggregation and collection (S3 → MinIO) | Declared |
| version-checker | Image drift metrics | Declared |
| nova | Helm chart drift (weekly CronJob) | Declared |
| intel-gpu-exporter | Intel iGPU utilisation metrics | Declared |
| Intel device plugins | Expose the Intel iGPU to pods for QuickSync | Declared |
| local-path-du | Per-PVC disk usage exporter | Declared |
| Pi-hole | DNS / ad blocking and aggregated LAN A records | Declared* |
| whoami | Personal blog | Declared |
| ezBookkeeping | Personal finance (Postgres-backed) | Declared |
| SparkyFitness | Fitness tracking (Postgres-backed) | Declared |
| Matrix | Synapse, Element Web, synapse-admin | Declared |
| Element Call | LiveKit SFU + lk-jwt, native services on VPS | Declared |
| Homarr | Homepage / launcher (`home.dobryops.com`) | Declared |
| Glance | Service and infrastructure dashboard | Declared |
| SearXNG | Metasearch | Declared |
| Uptime Kuma | Per-workload monitors and status page | Declared |
| speedtest-tracker | Internet speed history | Declared |
| go2rtc | Camera stream gateway | Declared |
| grafana-image-renderer | PNG renderer for Grafana panels | Declared |
| Attic | Hosted Nix binary cache (`badwater`) | Declared |
| Squid | HTTP forward proxy (LAN egress) | Declared |
| ncps | Nix binary cache proxy | Declared |
| Hale (Saxton) | Matrix Hermes agent; media API actions and read-only k8s observer | Enabled |
| MS Researcher | MS research KB writer, RSS enrichment and digest | Disabled |
| KotH DM | Matrix campaign agent; module and skills retained | Disabled |
| MS Researcher KB viewer | Independent read-only Logseq publisher | Declared |
| pangolin-kwg | Host-side kernel WG (engineer ↔ VPS) | Enabled |
| newt-cicd | In-cluster userspace WG for CI-managed GitOps | Declared |
| MetalLB | L2 LoadBalancer for per-service LAN IPs | Declared |
| cert-manager | Wildcard `*.dobryops.com` via Let's Encrypt DNS-01 | Declared |

</div>

These are repository declarations, **not a live health report**. A deployed workload, its Pangolin public-resource `enabled` flag, and LAN access are separate controls. For example, ArgoCD and Pi-hole remain declared while their public resources are disabled.

> \* Pi-hole serves DNS for the cluster's domains via per-workload `local-dns.nix` declarations aggregated into `FTLCONF_dns_hosts`. Setting it as the LAN's upstream DNS is a router-side change.

Mail hosting for `dobryops.com` is intentionally external via Proton Mail; this cluster does not run an SMTP/IMAP mail server.

Hale uses the `openai-codex` provider with `gpt-5.6-luna`. OAuth state remains mutable user data; authenticate or refresh it on `engineer` with:
`sudo -u hale -H /run/current-system/sw/bin/hermes auth add openai-codex --type oauth --no-browser`.

### Glance dashboard

**Home** is the service catalogue, with a native tabbed **Media** group: app shortcuts, library counts, streams, TV, movies, requests and indexer health. The separate Media page is removed; **Mobile** remains a compact view with research KB, SparkyFitness and RomM shortcuts added. All 15 existing custom API widgets retain their requests, credentials wiring and cache intervals.

Home covers the 30 user-facing HTTP resources, including Homarr, SearXNG, the research KB, SparkyFitness, RomM, pgAdmin, Uptime Kuma, Alertmanager, Speedtest and the camera. **`(LAN)`** identifies resources whose public Pangolin route is disabled; those links require the appropriate LAN/split-DNS access and do not enable public exposure. Raw Matrix/S3/registry/cache endpoints and Glance's own URL are deliberately not application launchers.

[Dashboard configuration](workloads/namespace/dashboard/apps/glance/config.nix) owns the grouping and shortcuts. Use real Simple Icons names, selfh.st logos where a brand is absent, and Material Design icons for generic functions. Sportarr's dark SVG needs `auto-invert`; colored logos do not. CDN-hosted icons still depend on their providers; existing custom icons are served locally.

Run the [maintenance check](workloads/namespace/dashboard/apps/glance/check.py) whenever resources, bookmarks, layout or icons change. It requires Python 3, Nix, `yq` and the cached locked flake inputs. It evaluates configuration without decrypting secrets; `--icons` contacts the configured icon providers, not application health APIs.

```bash
# Offline inventory, Media/Mobile layout, LAN labels and local icon checks:
python3 workloads/namespace/dashboard/apps/glance/check.py
# Also verify each public CDN icon URL returns a valid image:
python3 workloads/namespace/dashboard/apps/glance/check.py --icons
```

A newly declared frontend without exactly one Home shortcut fails the check: add its bookmark, or document an intentional API-only exclusion in the checker. This is an explicit maintenance gate, not automatic service discovery or a live health report.

Validated on 2026-09-08 with Glance `v0.8.6`: engineer's full build, 30 service shortcuts, 36 icon references, all seven Media tabs, and desktop/narrow-viewport browser checks. Browser API/RSS data was synthetic; this does not establish production backend health or deployment.

### SearXNG search

The [image pin](workloads/namespace/dashboard/apps/searxng/helm.nix) is `2026.9.8-3fdc6d753` with its registry digest. [Settings](workloads/namespace/dashboard/apps/searxng/settings.nix) merge upstream defaults by engine name: **Brave, DuckDuckGo and Bing** are enabled; Google and Startpage are disabled by default after returning empty results/errors. Other categories, including science, remain available. Glance opens the HTML search page; JSON output and DuckDuckGo autocomplete are retained.

On 2026-09-08, an isolated candidate pod on engineer using these settings passed ten ordinary queries: all three web engines returned results, with no engine errors, in 0.62–1.57 seconds. HTML, JSON and autocomplete also passed. This is a bounded candidate test, not proof of production deployment or continuing provider availability. Saved browser engine preferences can override defaults; retest in a fresh session after rollout.

Functional smoke check after deployment (configured Kubernetes access required):

```bash
# Terminal 1: expose only a loopback port; stop with Ctrl-C afterwards.
kubectl -n dashboard port-forward service/searxng 18080:8098
```

```bash
# Terminal 2: /healthz alone does not test external search engines.
set -o pipefail
curl --fail --silent --show-error --max-time 20 --get \
  http://127.0.0.1:18080/search \
  --data-urlencode 'q=NixOS documentation' \
  --data-urlencode 'format=json' \
  --data-urlencode 'language=en' \
  | jq -e '(.results | length > 0) and (.unresponsive_engines | length == 0)'
```

To isolate a failure, add `--data-urlencode 'engines=bing'` (or `brave` / `duckduckgo`) and space requests out. Keep external queries out of Kubernetes probes. CAPTCHA/429 responses are provider failures, not a reason to disable suspension backoff or blindly increase timeouts. No new proxy, VPN, or timeout override is configured.

### Workload image refresh (2026-09-08)

These are the selected source versions, not a live rollout report. The eight image families cover the thirteen reported `ImageOutOfDate` alerts; existing chart versions and unrelated images remain unchanged.

| Image | Version | Source |
|---|---|---|
| Argo CD | `v3.5.2` | [Argo CD Helm values](workloads/namespace/cicd/apps/argocd/helm.nix), both global and controller overrides |
| Glance | `v0.8.6` | [Glance Helm values](workloads/namespace/dashboard/apps/glance/helm.nix) |
| nginx | `1.31.5` | [KB viewer Helm values](workloads/namespace/knowledgebase/apps/ms-researcher-kb/helm.nix) |
| curl | `8.22.0` | [qBittorrent port-sync](workloads/namespace/media/apps/qbittorrent/helm.nix) |
| Grafana | `13.2.1` | [kube-prometheus-stack Helm values](workloads/namespace/monitoring/apps/kube-prometheus-stack/helm.nix) |
| k8s-sidecar | `2.11.2` | Grafana Helm values above and [Loki Helm values](workloads/namespace/monitoring/apps/loki/helm.nix) |
| Loki | `3.7.7` | [Loki Helm values](workloads/namespace/monitoring/apps/loki/helm.nix) |
| Uptime Kuma | `2.5.3` | [Uptime Kuma Helm values](workloads/namespace/monitoring/apps/uptime-kuma/helm.nix) |

The full engineer NixOS toplevel build passed. All eight affected chart releases rendered in upgrade mode before/after the change (165 resources per render set); checks confirmed only intended image-value fields changed and Service/Ingress/PVC specifications were unchanged. Registry manifest digests and Linux/amd64 availability were also checked. These checks do not deploy workloads or validate secret-substituted production manifests.

Existing digest pins are preserved: change tag and digest together, including Grafana sidecar's separate `sha` field. Docker Hub and Quay publish the same target sidecar digest. Do not change alert exclusions to hide pending rollouts.

Before deploying the stateful updates, take a consistent Uptime Kuma `/app/data` backup. A read-only live check on 2026-09-08 confirmed Grafana's `storage` volume is **`emptyDir`**, while Kuma uses the `uptime-kuma` PVC: protect Grafana's database/unprovisioned state before replacing its pod, or explicitly approve a persistent-storage migration. Keep Loki schema, storage and retention settings unchanged. Afterwards verify Argo reconciliation, Glance widgets, KB content, qBittorrent VPN/port synchronization, Grafana dashboard/datasource watches, Loki ingestion/historical queries, and Kuma monitors/notifications. Check running image IDs and allow for version-checker's 30-minute cache plus scrape/evaluation delay; the alert's 72-hour duration delays firing, not resolution. Roll back through the Nix pins, restoring compatible data if a database migration requires it.

### MS Researcher Agent

`services.ms-researcher` and all its agent, Matrix, skills, cron, MCP, KB and Git-sync flags are **disabled** in `nodes/engineer/default.nix`. The configuration was retained after the Codex subscription was cancelled. The independently imported `knowledgebase` viewer is still configured; that does not mean research or Git synchronization is running.

When enabled, the module manages a dedicated Hermes Matrix bot and a mutable Logseq-style KB at `/var/lib/ms-researcher/kb`, bind-mounted at `/home/ms-researcher/kb`.

Preserved intent when enabled (implemented through agent skills/jobs, not a guarantee of completed research):
- Watches curated MS research/news/trial/practical-living RSS feeds every 6 hours.
- Scores source credibility and filters out low-trust, miracle-cure, product-pitch, or unverified claims.
- Verifies research through PubMed, CrossRef, ClinicalTrials.gov, SearXNG, and official/recognized MS sources before writing KB pages.
- Writes citation-grounded pages, run reports, journals, and weekly reports under the KB tree.
- Publishes a reader-friendly Monday morning "This week in MS" digest at 08:00 Europe/Sofia.
- The independent `knowledgebase` viewer exposes the KB at `ms-kb.dobryops.com`, even while the writer is disabled.
- Schedules generated RSS raw-cache cleanup after the digest; the preserved cleanup example needs the V2-layout/safety fixes recorded in the project knowledge base before re-enabling it.
- Syncs the KB to GitLab every 10 minutes when `/var/lib/ms-researcher/kb` has been initialized as a git repo.

Operational notes (writer setup applies only after re-enabling it):
- Codex subscription auth is mutable user state. For the preserved provider, authenticate with:
  `sudo -u ms-researcher -H /run/current-system/sw/bin/hermes auth add openai-codex --type oauth --no-browser`
- The KB git repo is initialized manually as `ms-researcher`; Nix wires git/ssh/sops credentials but does not clone over mutable state.
- The web viewer pulls `git@gitlab.dobryops.com:knowledge-base/ms-researcher-kb.git` over SSH every few minutes and republishes the static Logseq view when the repo changes.
- The viewer redirects the empty Logseq landing route to `Start Here`, which the agent keeps updated as the curated KB front door.
- The KB uses a V2 date/type layout: canonical content in `content/{studies,trials,practical,reports,queries}/...`, journals in `journals/YYYY/MM/YYYY_MM_DD.md`, and navigation pages in `pages/`.
- The agent's `kb-maintain` skill self-heals legacy flat files into that layout and refreshes `Start Here`, `Index`, and sub-index pages.
- The viewer also exposes raw KB file-tree browsing at `/kb/`; `.git` paths are blocked.
- The viewer is read-only; editing remains through GitLab/local Logseq or the writer if re-enabled. It publishes the full KB, including raw files, so do not put credentials or private material in that repository.
- `koth-dm` is also disabled on `engineer`; `hale` is enabled.
- See [KB lifecycle and known limitations](docs/project-context.md#agent-and-research-kb-lifecycle) before re-enabling automation.

---

## Quick Start

### Prerequisites

- NixOS (or Linux with Nix)
- Basic familiarity with Nix and Kubernetes
- A managed Pangolin VPS (`pangolin`) and the home server (`engineer`) declared in this flake

### Setup

**1. Clone the repo**
```bash
git clone https://github.com/bovf/homelab-overkill.git
cd homelab-overkill
nix develop
```

The dev shell supplies operator tools and generates SSH aliases; entering it can decrypt node metadata into `.cache/` and install Git hooks. It is not a side-effect-free inspection command.

**2. Pull secrets from Bitwarden**
```bash
nix run .#secrets -- pull
nix run .#secrets -- init
nix run .#secrets -- bootstrap <node>  # engineer or pangolin
```

Bootstrap adds recipients but does **not** rekey an existing encrypted file by default. Review `.sops.yaml`, then run `nix run .#secrets -- rekey` if recipients changed before installing. See [mutable state and recovery](docs/project-context.md#mutable-state-and-recovery).

Secrets live in one encrypted file, `secrets/secrets.yaml`, including the
Pangolin VPS service environment and LiveKit credentials. SOPS recipients are
managed in `.sops.yaml`; raw SSH public keys are supported via
`SOPS_AGE_SSH_PRIVATE_KEY_FILE`, while existing converted age recipients remain
for compatibility during migration.

**3. Install on your node**

**Destructive:** installation runs disko partitioning and reboots the target. Verify its disk configuration and backups first. After bootstrap, re-enter `nix develop` if node metadata was unavailable on the first shell entry.

```bash
nix run .#deploy -- install engineer-local
nix run .#deploy -- install pangolin-remote
```

`nixos-anywhere` remains the one-shot installer for SSH-reachable machines.
`pangolin` is remote-only, so it has no `pangolin-local` deploy target. For
rescue/offline workflows, build per-node ISOs with:

```bash
nix build .#engineer-install-iso
nix build .#pangolin-install-iso
```

**4. Update an existing node**
```bash
nix run .#deploy -- update engineer-local
nix run .#deploy -- update pangolin-remote
```

`pangolin` is remote-only. Its generated SSH target matches:

```sshconfig
Host pangolin pangolin-remote
  HostName <vps-public-ip>       # from .cache/nodes.json
  User <ssh-user>                # from .cache/nodes.json
  IdentityFile ~/.ssh/$USER      # per-machine convention, never configured
```

Deployment address and SSH-user metadata are read from the encrypted `nodes:`
block in `secrets/secrets.yaml`, rather than embedded in the flake's deploy targets. Run `nix run .#bootstrap`
once (or just enter the dev shell with your age key present) to materialize
them into the gitignored `.cache/nodes.json`; dev shells and nix apps resolve
them from there at runtime. The SSH identity is always the machine-local
`~/.ssh/$USER` key (e.g. `~/.ssh/heavy` on heavy).

`engineer-remote` is resolved from targeted SOPS scalar lookups for the Pangolin
SSH resource host/port. The dev shell never decrypts the full secrets file for
SSH config generation.

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
       │ Pangolin VPS              │         │ MetalLB (LAN-direct)    │
       │ • managed as node         │         │ • Per-service LAN IPs   │
       │   `pangolin`              │         │ • Pi-hole local DNS     │
       │ • pangolin/gerbil/traefik │         └─────────────────────────┘
       │ • LiveKit + lk-jwt        │
       │ • kernel-WG/newt ingress  │
       └────────────────────────────┘
```

| Step | Component     | Role                                                         |
|------|---------------|--------------------------------------------------------------|
| 1    | Nix Flakes    | Describe the entire infrastructure as code                   |
| 2    | SOPS          | Encrypt secrets before version control                       |
| 3    | k3s           | Lightweight Kubernetes runtime                               |
| 4    | Helm          | Application packaging + deploy                               |
| 5    | Pangolin VPS  | Public edge: Pangolin, gerbil, Traefik, LiveKit, lk-jwt      |
| 5a   | pangolin-kwg  | Host-side kernel-WireGuard tunnel from engineer to the VPS   |
| 6    | Olm clients   | WG VPN replacing Tailscale; direct access to tunnel IPs      |
| 7    | MetalLB       | L2 LoadBalancer for per-service LAN IPs                      |
| 8    | Pi-hole       | Cluster DNS upstream; LAN A records + DoH adlist             |
| 9    | cert-manager  | Wildcard `*.dobryops.com` via Let's Encrypt DNS-01           |
| 10   | Reloader      | Rolling-restarts pods when watched ConfigMaps/Secrets change |
| 11   | Keel          | Rolls opted-in workloads when their configured image changes |
| 12   | Change flow   | Edit → validate → commit → explicitly deploy host configuration |

---

## Security Model

For setup and app state that are not fully Nix-declarative, see [mutable state and recovery](docs/project-context.md#mutable-state-and-recovery).

Credentials are intended to live in SOPS and be injected at activation/runtime. Domains, email addresses, public keys and network configuration also appear in plaintext source; this is **not** a blanket guarantee that the repository contains no sensitive metadata. `nodes/pangolin/guards.nix` has an unresolved security TODO concerning its plaintext admin IP allowlist.

The VPS deliberately exposes web, SSH, WireGuard and media ports. Public-resource enablement and SSO are per-resource choices, not universal protection for every access path.

### How Secrets Reach Workloads

```
secrets/secrets.yaml  (SOPS encrypted)
         |
         +--> engineer: sops-nix renders k3s manifests/templates
         |              into /var/lib/rancher/k3s/server/manifests/
         |              -> k3s auto-applies K8s Secrets/ConfigMaps/HelmCharts
         |
         +--> pangolin: sops-nix renders native service secret files
                        for services.pangolin, LiveKit, and lk-jwt-service
```

### Pangolin Blueprint System

Workloads needing Pangolin exposure declare a `pangolin-blueprint.nix` entry. Activation renders the full organization blueprint and attempts `pangolin-kwg-blueprint-sync.service` to publish it to the integration API. Routine resource updates do not require manual UI edits or an in-cluster aggregator pod for engineer-side resources; initial site/API-key provisioning is still external.

The cicd-gitops site keeps the legacy ConfigMap aggregator (cronjob in `cicd/apps/newt/`) because its blueprint is CI-managed, not nix-managed.

Supports:
- **HTTP resources** — SSO, custom rules, headers
- **Raw TCP/UDP resources** — SSH, k8s API, gitlab-shell, etc.

### sops-nix Symlink Patch

The local `sops-install-secrets` patch recreates rendered-file symlinks on activation, giving k3s a fresh change signal when template content changes. Preserve this compatibility patch when updating sops-nix; verify reconciliation on the node rather than assuming a fixed deployment latency.

### SOPS SSH Recipient Model

The repo uses SOPS age recipients from two sources:

- existing native/converted `age1...` recipients kept for compatibility
- raw SSH public-key recipients for trusted machines, including the MacBook Air
  RSA key

Raw SSH recipients are decrypted by setting `SOPS_AGE_SSH_PRIVATE_KEY_FILE` on
managed hosts:

- `engineer` currently uses `/root/.ssh/id_ed25519`
- `pangolin` uses `/root/.ssh/theadministrator`

Bootstrap stages host-specific key names for future installs, while runtime
configuration only lists keys known to exist on the current hosts to avoid noisy
`sops-install-secrets` missing-key warnings.

### Git Hooks and Formatting

The dev shell auto-installs two Nix-store-managed hooks when entering `nix develop`
(or another shell that runs `.#devShells.<system>.default`'s shell hook). Existing manual,
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

No categorical suppression — no path-based allowlists, no regex allowlists. Pin a finding in commit A line 286, and a similar-looking real secret in commit B line 12 still fires. Each pin is a deliberate, reviewable line with a written reason. Both scanners are added to the devShell `packages` so they're on `$PATH` inside `nix develop` for ad-hoc use too. TruffleHog verification may contact providers; the scan is not an offline documentation check.

---

## Repository Structure

```
.
├── flake.nix                  # Entry point + sops.package patch + Hermes uv2nix overlay
├── flake.lock
├── .sops.yaml
├── .gitleaksignore            # gitleaks per-finding allowlist (fingerprints + reasons)
├── .trufflehog-allowlist      # trufflehog per-finding allowlist (fingerprints + reasons)
├── README.md
├── docs/
│   ├── project-context.md     # Source map, mutable state, checks, docs maintenance
│   └── housekeeping-audit.md  # Open issues, impacts, proposed fixes, verification
│
├── nix/                       # Nix apps and tooling
│   ├── apps/
│   │   ├── deploy.nix         # nixos-rebuild-ng based deploy script
│   │   ├── kubeconfig.nix     # Kubeconfig bootstrap for local k9s/kubectl
│   │   ├── secrets.nix        # Bitwarden secrets management
│   │   ├── fmt.nix            # `nix run .#fmt` — Alejandra formatter/check app
│   │   ├── scan.nix           # `nix run .#scan` — gitleaks + trufflehog wrapper
│   │   └── utilities.nix      # Node status checks
│   ├── images/                # nixos-generators rescue/install ISO outputs
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
│   └── pangolin/              # VPS edge node: Pangolin, Traefik, LiveKit
│   │   ├── configuration.nix
│   │   ├── disk-config.nix
│   │   ├── services.nix
│   │   ├── firewall.nix
│   │   ├── element-call.nix
│   │   ├── guards.nix
│   │   └── virtualization.nix
│   # sentry-level-01 exists only as commented flake metadata; no node directory
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
│       ├── kube-system/       # traefik, coredns, node-feature-discovery
│       ├── intel-device-plugins/  # Intel GPU device plugin + operator
│       ├── knowledgebase/     # MS Researcher KB read-only Logseq published web UI
│       ├── database/          # postgresql, minio (+ loki bucket init), pgadmin
│       ├── cicd/              # gitlab, gitlab-nix-runner, argocd, reloader, keel, newt
│       ├── dashboard/         # glance, searxng
│       ├── media/             # jellyfin, sonarr, radarr, prowlarr, bazarr,
│       │                      # jellyseerr, qbittorrent, nzbget, sportarr, romm
│       ├── monitoring/        # kube-prometheus-stack, loki, alloy,
│       │                      # grafana-image-renderer, version-checker,
│       │                      # nova, intel-gpu-exporter,
│       │                      # local-path-du-exporter, grafana-dashboards,
│       │                      # uptime-kuma, speedtest-tracker
│       │                      #   (incl. node-overview desktop +
│       │                      #    node-overview-mobile-{s,m,l})
│       ├── cert-manager/      # letsencrypt cluster issuer
│       ├── dns/               # pihole
│       ├── finance/           # ezbookkeeping
│       ├── health/            # sparkyfitness
│       ├── matrix/            # synapse, element, synapse-admin
│       ├── homarr/            # homepage / launcher (home.dobryops.com)
│       ├── proxy/             # attic-cache, squid, ncps
│       ├── surveillance/      # go2rtc
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
│   ├── ms-researcher-cron/    # Preserved RSS/digest/cleanup jobs (agent disabled)
│   ├── koth-dm.nix, koth-dm-skills/  # Preserved campaign agent (disabled)
│   └── mcps/                 # Six FastMCP Python packages for research/campaign tools
│
└── secrets/                   # SOPS-encrypted secrets
    ├── secrets.yaml           # Encrypted engineer/workload/Pangolin values (age)
    └── default.nix            # sops.secrets declarations
```

---

## Workload Pattern

Most chart-backed apps use this structure; import only the components needed:

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

Use `sops.templates` for YAML requiring secret placeholders. Non-secret objects use `services.k3s.manifests`; PostgreSQL is a raw StatefulSet, and bundled Traefik/CoreDNS charts use `HelmChartConfig`. Apps can also own `uptime.nix`, init Jobs, PVCs and service definitions. See the [change checklist](docs/project-context.md#keeping-documentation-current).

### Three access paths

A resource is reachable via one or more of:

| Path | Hostname | Goes through | Used when |
|---|---|---|---|
| **Pangolin public** | `*.dobryops.com` | Public IP → pangolin VPS → kwg tunnel → backend | Off-LAN, no VPN. Enablement and SSO depend on the resource. |
| **Pangolin client (olm)** | Tunnel IP (`100.89.128.x`) or DNS | Mac/iOS olm WG → pangolin VPS → kwg tunnel → backend | Off-LAN with VPN installed. No per-application public ports needed. |
| **LAN-direct** | LAN IP (`192.168.2.x`), resolved via Pi-hole | MetalLB L2 announce → traefik → backend | On-LAN. No round-trip via the VPS. |

Existing workload resources explicitly set `viaKernelWg = true`; the option default is `false`. The kernel-WG path sends traffic to `100.89.128.16:<unique-service-port>`, where kube-proxy's Service `externalIPs` rules deliver it to the backend pod. Host SSH and the k3s API listen directly on that tunnel IP.

The sync service converts rendered YAML to base64-encoded JSON and PUTs the **whole organization blueprint** to Pangolin's integration API. Activation attempts this on every rebuild; check the service result separately, because a successful rebuild does not prove the API sync succeeded.

### Local DNS aggregation

Each workload's `local-dns.nix` declares one `{ host, ip }` entry under `workloads.localDnsRecords`. Pi-hole's helm chart collapses the attrset into `FTLCONF_dns_hosts`, which v6 reads into `dns.hosts[]` (UI-visible). Adding a new LAN-resolvable service is one file in the owning workload — no central registry edit.

### DNS topology

Pi-hole is the preferred split-horizon resolver; host and cluster configuration include public fallback resolvers. LAN clients use it only when configured on the router/client:

```
LAN clients  ──> 192.168.2.2 (Pi-hole) ──> 1.1.1.1 / 1.0.0.1
Cluster pods ──> 10.43.0.10 (CoreDNS) ──> Pi-hole / public fallbacks
```

`networking.nameservers = [ "192.168.2.2" "1.1.1.1" ]` makes engineer prefer Pi-hole. CoreDNS also has an explicit `dobryops.com` forwarding block with sequential Pi-hole, Cloudflare and Google fallback in `workloads/namespace/dns/apps/pihole/coredns-custom.nix`. Fallback can return public rather than LAN addresses, so not every lookup is guaranteed to pass through Pi-hole. Pi-hole's own pod uses `8.8.8.8/8.8.4.4` via `podDnsConfig` to avoid a resolver loop.

### TLS

Two terminators handle TLS, depending on the access path:

- **Public path** — VPS Traefik terminates TLS using Pangolin's ACME resolver. The current Nix configuration leaves DNS-01 unset (HTTP-01 default); it does not declare an edge wildcard certificate or prove Cloudflare proxying. Backend HTTP/HTTPS is selected per resource. LiveKit and lk-jwt signaling are separate native VPS routes.
- **LAN-direct path** — cert-manager is configured to issue a wildcard `*.dobryops.com` cert from Let's Encrypt via the Cloudflare **DNS-01** solver. Traefik references it as `tlsStore.default.defaultCertificate`. Successful issuance supplies publicly trusted LAN-side TLS without a per-device root CA; actual certificate readiness/expiry requires a live check.

---


<div align="center">
*Keep it simple. Keep it declarative. Keep secrets secret.*

**Star this repo if it sparked ideas for your own homelab.**

</div>
