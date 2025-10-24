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
nix run .#deploy -- install engineer
```

4. Update existing cluster:
```bash
nix run .#deploy -- update engineer
```

## How It Works

1. **Nix flakes** describe your infrastructure as code.
2. **SOPS** encrypts secrets before version control.
3. **k3s** provides a lightweight Kubernetes cluster.
4. **Helm** deploys applications with your config.
5. **Pangolin** creates private tunnels to services. Pangolin Tunnels CRDs to be implemented
6. **GitOps:** Edit config → commit → deploy. Everything is reproducible and version-tracked.

## Structure

```
.
├── flake.nix                  # Entry point
├── flake.lock
├── .sops.yaml
├── README.md
│
├── nix/                       # Nix apps (deploy, secrets utilities)
│   ├── apps/
│   │   ├── deploy.nix
│   │   └── secrets.nix
│   └── shells/
│
├── nodes/                     # NixOS machines
│   ├── engineer/              # Main node config
│   │   ├── hardware.nix
│   │   ├── disko.nix
│   │   └── services.nix
│   └── sentry-level-01/       # Future nodes (To be developed)
│
├── infrastructure/            # k3s cluster setup
│   └── k3s/
│       ├── cluster.nix
│       ├── networking.nix
│       └── server/
│
├── workloads/                 # Kubernetes namespaces & apps
│   └── namespace/
│       ├── kube-system/       # System components (traefik, nfd, intel-plugins)
│       ├── database/          # postgresql, minio, pgadmin
│       ├── cicd/              # gitlab, argocd
│       ├── media/             # jellyfin, sonarr, radarr, prowlarr, bazarr, jellyseerr, qbittorrent
│       ├── monitoring/        # kube-prometheus-stack
│       ├── cert-manager/      # Certificate management
│       ├── pangolin/          # Tunnels (newt)
│       ├── homepage/          # Dashboard
│       ├── resume/            # Reactive Resume
│       └── ghost/             # Blog
│
├── common/                    # Shared NixOS (base, services, users)
│
└── secrets/                   # SOPS secrets (encrypted)
```

## Philosophy

Keep it simple, keep it declarative, keep secrets secret. No open ports, (almost) no manual setup, no snowflake servers. Just code and reproducibility.

---

Made with ❤️ and ☕ from Sofia, Bulgaria.
