<div align="center">

<pre>
██████╗  ██████╗ ██████╗ ██████╗ ██╗   ██╗ ██████╗ ██████╗ ███████╗
██╔══██╗██╔═══██╗██╔══██╗██╔══██╗╚██╗ ██╔╝██╔═══██╗██╔══██╗██╔════╝
██║  ██║██║   ██║██████╔╝██████╔╝ ╚████╔╝ ██║   ██║██████╔╝███████╗
██║  ██║██║   ██║██╔══██╗██╔══██╗  ╚██╔╝  ██║   ██║██╔═══╝ ╚════██║
██████╔╝╚██████╔╝██████╔╝██║  ██║   ██║   ╚██████╔╝██║     ███████║
╚═════╝  ╚═════╝ ╚═════╝ ╚═╝  ╚═╝   ╚═╝    ╚═════╝ ╚═╝     ╚══════╝
</pre>

</div>

# DobryOps homelab

NixOS hosts, k3s workloads, encrypted secrets, and a WireGuard-connected public
edge. This repository describes configuration; it is not a live service-status
page or a backup of application data.

## The two machines

| Host | Responsibility | Deploy targets |
| --- | --- | --- |
| [`engineer`](nodes/engineer/default.nix) | Home server: k3s, application storage, Intel GPU, WireGuard, Hale | `engineer-local`, `engineer-remote` |
| [`pangolin`](nodes/pangolin/default.nix) | Public VPS: Pangolin, Gerbil, Traefik, LiveKit and Matrix JWT service; no Kubernetes | `pangolin-remote` |

```text
Public traffic → Pangolin VPS → WireGuard → Engineer → application
LAN traffic    → Pi-hole DNS  → MetalLB   → Traefik  → application

NixOS activation → k3s manifests → Helm controller / Kubernetes resources
```

Nix is the primary deployment path. ArgoCD is installed for separately managed
applications; it does not deploy the Nix-defined stack.

## What runs here

| Area | Main services |
| --- | --- |
| Development | GitLab, registry, regular and Nix-cache runners, ArgoCD, Keel, Reloader |
| Storage | PostgreSQL, MinIO, shared media PVCs |
| Media | Jellyfin, Sonarr, Radarr, Sportarr, Prowlarr, Bazarr, Jellyseerr/Seerr, qBittorrent, NZBGet, RomM |
| Monitoring | Prometheus, Grafana, Alertmanager, Loki, Alloy, Uptime Kuma, hardware/storage/version exporters |
| Daily use | Matrix/Element, Homarr, Glance, SearXNG, ezBookkeeping, SparkyFitness, blog, camera, research KB viewer |
| Platform | MetalLB, Pi-hole, cert-manager, Intel GPU plugins, Attic, ncps, Squid |

These are declarations, not health claims. Public access is a separate flag from
workload deployment and LAN access. **Hale is enabled; MS Researcher and KotH DM
are disabled.** The research KB viewer remains independently configured.

The [namespace inventory](docs/project-context.md#workloads) lists imported apps
and links to their entrypoints. Workload files own image/chart versions;
[`flake.lock`](flake.lock) owns dependency revisions—not a second table here.

## Common commands

Run from the repository root. Operational commands expect `nix develop` and
working SSH/SOPS access. Entering that shell can decrypt node metadata into
`.cache/`, generate SSH configuration, and install Git hooks.

| Task | Command |
| --- | --- |
| Enter operator environment | `nix develop` |
| Check selected Nix files | `nix run .#fmt -- --check flake.nix` |
| Check SSH access | `nix run .#deploy -- status engineer-local` |
| Fetch cluster-admin kubeconfig | `umask 077; eval "$(nix run .#kubeconfig -- engineer-local)"` |
| Activate Engineer changes | `nix run .#deploy -- update engineer-local` |
| Activate VPS changes with conservative build parallelism | `nix run .#deploy -- update pangolin-remote --low-cost` |
| Report disk/store usage | `nix run .#store-cleanup -- engineer-local --report` |

Read the [operations guide](docs/operations.md) before first use or a stateful
upgrade. `deploy test` **activates** configuration; it is not a dry run.
`deploy install` **partitions disks and reboots**. `update` (the standalone app)
updates dependencies; it does not deploy a host.

## Guides

| Need | Read |
| --- | --- |
| Architecture, app inventory and network paths | [Project map](docs/project-context.md) |
| SSH, secrets, installation, deployment, cleanup and data safety | [Operations](docs/operations.md) |
| Change a workload, run checks, understand CI | [Development](docs/development.md) |
| Back up Grafana or Kuma manually | [Monitoring backups](docs/monitoring-storage-backups.md) |
| Understand unresolved source limitations | [Known issues](docs/housekeeping-audit.md) |
| Provision the Basic WireGuard site or Heavy SSH route | [Engineer tunnel setup](nodes/engineer/bootstrapping.md) |

## Source layout

- [`flake.nix`](flake.nix): nodes, inputs, module composition, Hermes package overlay.
- [`nodes/`](nodes/): machine-specific OS, disk, service and network configuration.
- [`common/`](common/default.nix): Engineer base/users and Hermes agent modules; not imported by the VPS.
- [`infrastructure/`](infrastructure/default.nix): k3s, MetalLB and host-side WireGuard/blueprint sync.
- [`workloads/`](workloads/default.nix): namespace/app imports and shared exposure, DNS and monitoring options.
- [`nix/`](nix/): operator apps, development shell, install ISOs and the SOPS compatibility patch.
- [`secrets/`](secrets/default.nix): secret declarations and the SOPS-encrypted payload.

**Nix rebuilds configuration, not your data.** Keep recoverable off-host copies
of databases, PVCs, Pangolin state and required keys. A NixOS generation rollback
does not undo application database migrations.
