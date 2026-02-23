<div align="center">

```
██████╗  ██████╗ ██████╗ ██████╗ ██╗   ██╗ ██████╗ ██████╗ ███████╗
██╔══██╗██╔═══██╗██╔══██╗██╔══██╗╚██╗ ██╔╝██╔═══██╗██╔══██╗██╔════╝
██║  ██║██║   ██║██████╔╝██████╔╝ ╚████╔╝ ██║   ██║██████╔╝███████╗
██║  ██║██║   ██║██╔══██╗██╔══██╗  ╚██╔╝  ██║   ██║██╔═══╝ ╚════██║
██████╔╝╚██████╔╝██████╔╝██║  ██║   ██║   ╚██████╔╝██║     ███████║
╚═════╝  ╚═════╝ ╚═════╝ ╚═╝  ╚═╝   ╚═╝    ╚═════╝ ╚═╝     ╚══════╝
```

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

| Service           | Purpose                          | Status   |
|-------------------|----------------------------------|:--------:|
| GitLab            | Git, CI/CD, container registry   | Active   |
| ArgoCD            | GitOps                           | Active   |
| MinIO             | S3 object storage                | Active   |
| PostgreSQL        | SQL database                     | Active   |
| Jellyfin          | Media streaming                  | Active   |
| Sonarr            | TV show automation               | Active   |
| Radarr            | Movie automation                 | Active   |
| Prowlarr          | Indexer management               | Active   |
| Bazarr            | Subtitle automation              | Active   |
| Jellyseerr        | Media request portal             | Active   |
| qBittorrent       | Torrent client                   | Active   |
| NZBGet            | Usenet client                    | Active   |
| pgAdmin           | Postgres web admin               | Active   |
| Grafana           | Metrics & dashboards             | Active   |
| Pi-hole           | DNS / ad blocking                | Partial* |
| Homepage          | Dashboard                        | Active   |
| Ghost             | Blog                             | Active   |
| Newt              | Private tunnel access            | Active   |
| Reactive Resume   | Resume builder                   | Active   |

</div>

> \* Pi-hole is deployed and functional for ad blocking, but not yet configured as the network's central DNS server.

---

## Quick Start

### Prerequisites

- NixOS (or Linux with Nix)
- Basic familiarity with Nix and Kubernetes
- A VPS running Pangolin to connect Newt with

### Setup

**1. Clone the repo**
```bash
git clone https://github.com/dobryops/homelab.git
cd homelab
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

---

## How It Works

```
┌─────────────┐    ┌──────────┐    ┌───────────┐    ┌──────────────┐
│  Nix Flakes │───>│   SOPS   │───>│    k3s    │───>│     Helm     │
│  (IaC defn) │    │(encrypted│    │(k8s layer)│    │ (app deploy) │
└─────────────┘    │ secrets) │    └───────────┘    └──────────────┘
                   └──────────┘           │
                                          v
                               ┌──────────────────┐
                               │    Pangolin       │
                               │ (private tunnels) │
                               └──────────────────┘
```

| Step | Component     | Role                                               |
|------|---------------|----------------------------------------------------|
| 1    | Nix Flakes    | Describe your entire infrastructure as code        |
| 2    | SOPS          | Encrypt secrets before version control             |
| 3    | k3s           | Run a lightweight Kubernetes cluster               |
| 4    | Helm          | Deploy applications with declarative config        |
| 5    | Pangolin      | Create private tunnels to services                 |
| 6    | Reloader      | Auto rolling-restart Newt on secret changes        |
| 7    | GitOps        | Edit → commit → deploy. Always reproducible        |

---

## Security Model

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

Each workload self-registers via a `pangolin-blueprint.nix` file. The `newt` aggregator collects all registrations and renders one **blueprint Secret** per Pangolin instance - fully declarative, no central ConfigMap required.

Supports:
- **HTTP resources** - SSO, custom rules, headers
- **Raw TCP/UDP resources** - non-HTTP services like SSH

### sops-nix Symlink Patch

k3s detects manifest changes via `mtime + SHA256` on the file inode - symlink `mtime` never changes when target content changes. A patch to `sops-install-secrets` forces symlinks to be **recreated on every activation**, giving them a fresh `mtime` so k3s re-applies updated manifests within **~15 seconds**.

### Pre-commit Hook

`.git/hooks/pre-commit` blocks commits containing `*.dobryops.com` domains or `dobry@` email patterns in any staged `.nix` file. `flake.nix` is allowlisted (k3s TLS SAN requires the domain at build time).

---

## Repository Structure

```
.
├── flake.nix                  # Entry point + sops-nix patch overlay
├── flake.lock
├── .sops.yaml
├── README.md
│
├── nix/                       # Nix apps and tooling
│   ├── apps/
│   │   ├── deploy.nix         # nixos-rebuild-ng based deploy script
│   │   └── secrets.nix        # Bitwarden secrets management
│   ├── patches/
│   │   └── sops-always-recreate-symlink.patch
│   └── shells/
│
├── nodes/                     # NixOS machines
│   ├── engineer/              # Main node config
│   │   ├── hardware.nix
│   │   ├── disko.nix
│   │   └── services.nix
│   └── sentry-level-01/       # Future nodes
│
├── infrastructure/            # k3s cluster setup
│   └── k3s/
│       ├── cluster.nix
│       ├── networking.nix
│       └── server/
│
├── workloads/                 # Kubernetes namespaces & apps
│   ├── default.nix
│   └── namespace/
│       ├── kube-system/       # traefik, nfd, intel-plugins
│       ├── database/          # postgresql, minio, pgadmin
│       ├── cicd/              # gitlab, argocd, reloader
│       ├── media/             # jellyfin, sonarr, radarr, prowlarr,
│       │                      # bazarr, jellyseerr, qbittorrent, nzbget
│       ├── monitoring/        # kube-prometheus-stack
│       ├── cert-manager/      # letsencrypt cluster issuer
│       ├── pangolin/          # newt tunnel client + blueprint aggregator
│       ├── mumble/            # voice server
│       ├── resume/            # Reactive Resume
│       ├── dns/               # pihole
│       ├── homepage/          # dashboard
│       └── ghost/             # blog
│
├── common/                    # Shared NixOS modules (base, services, users)
│
└── secrets/                   # SOPS-encrypted secrets
    ├── secrets.yaml           # Encrypted values (age)
    └── default.nix            # sops.secrets declarations
```

---

## Workload Pattern

Every app follows a consistent, predictable structure:

```
workloads/namespace/<ns>/apps/<app>/
├── default.nix              # imports list
├── helm.nix                 # HelmChart manifest  (via sops.templates)
├── middleware.nix            # Traefik Middleware  (via sops.templates)
├── secret.nix               # K8s Secrets with injected credentials
└── pangolin-blueprint.nix   # Registers app as a Pangolin resource
```

> All `helm.nix` and `middleware.nix` files use `sops.templates` - domain names and credentials are **never present in git**.

---

<div align="center">
*Keep it simple. Keep it declarative. Keep secrets secret.*

**Star this repo if it sparked ideas for your own homelab.**

</div>
