# DobryOps Homelab

[![NixOS](https://img.shields.io/badge/NixOS-5277C3?style=for-the-badge&logo=nixos&logoColor=white)](https://nixos.org)
[![Kubernetes](https://img.shields.io/badge/Kubernetes-326CE5?style=for-the-badge&logo=kubernetes&logoColor=white)](https://kubernetes.io)
[![SOPS](https://img.shields.io/badge/SOPS-FFA500?style=for-the-badge&logo=mozilla&logoColor=white)](https://github.com/mozilla/sops)

A declarative, reproducible home infrastructure stack on Kubernetes and NixOS with encrypted secrets and no exposed ports.

## What This Is

A self-hosted platform built entirely from version-controlled configs. Everything—infrastructure, applications, databases, secrets, and tunnels—is defined in code and reproducible from scratch.

Uses Nix flakes to manage NixOS + k3s + Helm charts, SOPS for secure secret storage, and Pangolin for private network access.

## Services

| Service         | Purpose                        | Status  |
|-----------------|--------------------------------| ------- |
| GitLab          | Git, CI/CD, container registry | Active  |
| MinIO           | S3 object storage              | Active  |
| PostgreSQL      | SQL database                   | Active  |
| Jellyfin        | Media streaming                | Active  |
| Sonarr          | TV show automation             | Active  |
| Radarr          | Movie automation               | Active  |
| Prowlarr        | Indexer management             | Active  |
| Bazarr          | Subtitle automation            | Active  |
| Jellyseerr      | Media request portal           | Active  |
| qBittorrent     | Torrent client                 | Active  |
| NZBGet          | Usenet client                  | Active  |
| pgAdmin         | Postgres web admin             | Active  |
| Grafana         | Metrics & dashboards           | Active  |
| Newt            | Private tunnel access          | Active  |
| Reactive Resume | Resume builder                 | Active  |
| Ghost           | Blog                           | Next    |
| Homepage        | Dashboard                      | Planned |
| Pi-hole         | DNS/ad blocking                | Planned |
| ArgoCD          | GitOps Instance                | Planned |
| Nextcloud       | Personal cloud/NAS             | Planned |
| Longhorn        | Block storage for NAS          | Planned |

## Quick Start

### Prerequisites

- NixOS (or Linux with Nix)
- Basic familiarity with Nix and Kubernetes
- VPS Running Pangolin to connect newt with

### Setup

1. Clone the repo:
```bash
git clone https://github.com/dobryops/homelab.git
cd homelab
```

2. Pull secrets from Bitwarden:
```bash
nix run .#secrets -- pull
nix run .#secrets -- init
nix run .#secrets -- bootstrap <node>
```

3. Install on your node:
```bash
nix run .#deploy -- install engineer-local
```

4. Update existing cluster:
```bash
nix run .#deploy -- update engineer-local
```

## How It Works

1. **Nix flakes** describe your infrastructure as code.
2. **SOPS** encrypts secrets before version control.
3. **k3s** provides a lightweight Kubernetes cluster.
4. **Helm** deploys applications with your config.
5. **Pangolin** creates private tunnels to services.
6. **GitOps:** Edit config → commit → deploy. Everything is reproducible and version-tracked.

## Security Model

No sensitive data exists in plain text in this repository. Every domain name, credential, email address, and API key is encrypted at rest via SOPS and injected at runtime.

### How secrets reach workloads

- **sops-nix** decrypts `secrets/secrets.yaml` on each `nixos-rebuild switch` and renders `sops.templates` entries — YAML files with secret values substituted — directly into `/var/lib/rancher/k3s/server/manifests/`
- **k3s** auto-applies every YAML in that directory, creating the corresponding Kubernetes objects (HelmCharts, Secrets, ConfigMaps, Middlewares, Ingresses, etc.)
- **Pods** mount the resulting K8s Secrets as volumes or environment variables

### Pangolin blueprint system

Each workload registers itself as a Pangolin resource via a `pangolin-blueprint.nix` file. The `newt` aggregator collects all registrations and renders one blueprint Secret per Pangolin instance — fully declarative, no central configmap required.

### sops-nix symlink patch

sops-nix places symlinks in the k3s manifests directory. k3s detects changes via `mtime + SHA256` on the file inode — symlink mtime never changes when target content changes. A patch to `sops-install-secrets` (`nix/patches/sops-always-recreate-symlink.patch`) forces symlinks to be recreated on every activation, giving them a fresh mtime so k3s detects and re-applies updated manifests within 15 seconds.

### Pre-commit hook

`.git/hooks/pre-commit` blocks commits containing `*.dobryops.com` domains or `dobry@` email patterns in any staged `.nix` file. `flake.nix` is allowlisted (k3s TLS SAN requires the domain at build time).

## Structure

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
│   │   └── sops-always-recreate-symlink.patch  # k3s manifest detection fix
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
│   ├── default.nix            # pangolinInstances + pangolinResources NixOS options
│   └── namespace/
│       ├── kube-system/       # traefik, nfd, intel-plugins
│       ├── database/          # postgresql, minio, pgadmin
│       ├── cicd/              # gitlab
│       ├── media/             # jellyfin, sonarr, radarr, prowlarr, bazarr,
│       │                      # jellyseerr, qbittorrent, nzbget
│       ├── monitoring/        # kube-prometheus-stack
│       ├── cert-manager/      # letsencrypt cluster issuer
│       ├── pangolin/          # newt tunnel client + blueprint aggregator
│       ├── mumble/            # voice server
│       ├── resume/            # Reactive Resume
│       └── ghost/             # Blog (planned)
│
├── common/                    # Shared NixOS modules (base, services, users)
│
└── secrets/                   # SOPS-encrypted secrets
    ├── secrets.yaml           # Encrypted values (age)
    └── default.nix            # sops.secrets declarations
```

## Workload Pattern

Each app follows a consistent structure:

```
workloads/namespace/<ns>/apps/<app>/
├── default.nix          # imports list
├── helm.nix             # HelmChart manifest (via sops.templates)
├── middleware.nix        # Traefik Middleware (via sops.templates)
├── secret.nix           # K8s Secrets with injected credentials
└── pangolin-blueprint.nix  # Registers app as Pangolin resource
```

All `helm.nix` and `middleware.nix` files use `sops.templates` so that domain names and credentials are never present in the git repository.

## Philosophy

Keep it simple, keep it declarative, keep secrets secret. No open ports, no manual setup, no snowflake servers. Just code and reproducibility.

---

Made with love and coffee from Sofia, Bulgaria.
