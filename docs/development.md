# Development

[README](../README.md) · [Project map](project-context.md) · [Operations](operations.md)

## Change a workload

Start at `workloads/namespace/<namespace>/default.nix`, then the app's
`apps/<app>/default.nix`. Imports are explicit; adding a directory does nothing.
Follow the neighboring app rather than introducing a new deployment mechanism.

| File / setting | Responsibility |
| --- | --- |
| `helm.nix` | HelmChart values; or use raw `services.k3s.manifests` where appropriate |
| `secret.nix` / `sops.secrets` | Runtime credential/domain declarations and Kubernetes Secrets |
| `middleware.nix` | App-specific Traefik headers/behavior; not automatically authentication |
| `pangolin-blueprint.nix` | Public exposure, SSO choice, WG backend port, optional LAN IP |
| `local-dns.nix` | LAN A record aggregated into Pi-hole |
| `uptime.nix` | Monitor declaration aggregated into Kuma |
| `external-services.nix` | Sibling tunnel Service when a chart does not propagate `externalIPs` |

For an addition or change:

1. Wire the imports, namespace, storage and upstream dependencies.
2. Use SOPS placeholders for secrets; never evaluate decrypted values into Nix
   or put them in store paths. The [secret declarations](../secrets/default.nix)
   and encrypted Bitwarden/SOPS source must agree.
3. Keep WG Service ports unique on `100.89.128.16`; match blueprint `targetPort`
   to the **Service** port, not necessarily the container port. Choose an unused
   MetalLB IP and align its DNS record. Public enablement is a separate decision.
4. Add the frontend to [Glance](../workloads/namespace/dashboard/apps/glance/config.nix)
   or document an API-only exclusion in its checker. Run the coverage check.
5. If monitor definitions change, bump `bootstrapVersion` in
   [Kuma's bootstrap Job](../workloads/namespace/monitoring/apps/uptime-kuma/init-job.nix).
   Editing its ConfigMap alone does not rerun a completed Job. Image-only changes
   do not inherently need a bootstrap bump.
6. Run the relevant checks and update the owning guide in the same change.

For removal, plan controller/resource cleanup, route/DNS/monitor removal,
credential revocation and data retention explicitly. Symlink cleanup is not an
uninstaller. Do not delete PVCs simply because their source import disappeared.

### Dependencies and image upgrades

- `flake.lock` pins Nix dependencies. `helm.nix`/raw manifests own chart and
  container pins; a flake update does not refresh those versions.
- Change tags and digests together, including charts' separate `sha`/`digest`
  fields. Keep paired images (for example SparkyFitness frontend/server) aligned.
- Read migration notes and check chart schema/CRD compatibility, not just image
  availability. Preserve existing compatibility settings unless separately tested.
- Before deployment, build the affected host and render changed charts with
  synthetic placeholders. Neither proves decrypted manifests or live startup.
  Stateful updates also need the [data checklist](operations.md#data-and-recovery).

## Checks

Run from the repository root. Non-live checks below require cached locked Nix
inputs/tools for `--offline`; Python checks also require Python 3, and Glance/Attic/GitLab
checks require `yq` (Go implementation). They do not require secret decryption.

```bash
git diff --check
nix run --offline --no-write-lock-file .#fmt -- --check
nix eval --offline --no-write-lock-file --raw \
  .#nixosConfigurations.engineer.config.system.build.toplevel.drvPath
nix eval --offline --no-write-lock-file --raw \
  .#nixosConfigurations.pangolin.config.system.build.toplevel.drvPath
```

Focused assertions and synthetic checks (no real SSH, activation, API credentials,
reboots or store pruning; Attic's HTTP fixture binds only to loopback):

```bash
nix eval --offline --no-write-lock-file --impure --file nix/apps/check-heavy-ssh.nix
nix eval --offline --no-write-lock-file --impure --file nix/apps/check-pangolin.nix
nix eval --offline --no-write-lock-file --file nix/apps/check-ncps.nix
python3 -B nix/apps/check-deploy.py
python3 -B nix/apps/check-attic-cache.py
python3 -B nix/apps/check-gitlab.py
bash nix/apps/check-kubeconfig.sh
bash nix/apps/check-store-cleanup.sh
python3 -B workloads/namespace/dashboard/apps/glance/check.py
```

The [GitLab guide](../workloads/namespace/cicd/apps/gitlab/UPGRADE.md#local-validation-and-recovery)
also covers rendering every upgrade stop with downloaded public charts; its Redis
checks use disposable files and synthetic credentials.

Remove `--offline` when intentionally allowing Nix downloads. For a real code
change, build the affected target separately; this builds but does not activate:

```bash
nix build --no-write-lock-file --no-link \
  .#nixosConfigurations.engineer.config.system.build.toplevel
```

Use `pangolin` in that attribute for VPS changes. A `drvPath` evaluation is not a
build; a build is not a deployment; deployment is not an application health test.
The flake has no `checks` output; these scripts are separate entrypoints. The six
custom MCP packages currently set `doCheck = false`.

Optional network checks:

- `python3 -B workloads/namespace/dashboard/apps/glance/check.py --icons` checks
  public CDN icons, not application health.
- `nix run .#scan` runs Gitleaks and TruffleHog. TruffleHog verification may contact
  providers. Review per-finding allowlists and the scanner's
  [error-handling limitation](housekeeping-audit.md#tooling-and-validation).

## Formatting, hooks and CI

`nix run .#fmt --` formats all tracked Nix files; append filenames to scope it.
`--check` checks without editing. The dev shell installs a staged-Nix formatter
hook and a full-history Gitleaks pre-push hook, leaving manual non-symlink hooks
untouched. Hooks are local safeguards, not server-side CI enforcement.

[GitLab CI](../.gitlab-ci.yml) has two jobs:

| Trigger | Behavior |
| --- | --- |
| Schedule, web run or `RUN_FLAKE_UPDATE=1` | Update inputs, scan, build/cache through `.#update`, push an update branch/MR |
| Default-branch push | Force-push configured GitHub/Codeberg mirrors |

Ordinary feature-branch/MR pipelines have no general validation job. CI does not
deploy hosts. `nix run .#update` **modifies `flake.lock`**, formats changed Nix,
scans, and by default builds both hosts on x86_64 Linux. Set
`HOMELAB_UPDATE_PUSH_CACHE=1` with `ATTIC_TOKEN` to publish to Attic's `badwater`
cache; other systems skip builds unless `HOMELAB_UPDATE_BUILD=1`. It is neither a
read-only check nor a deployment command. Its failed-build handling remains an
[open issue](housekeeping-audit.md#tooling-and-validation).

## Keep docs aligned

- Update the app inventory when imports change and operational steps when their
  flags, side effects or recovery boundaries change.
- Link to version-owning source instead of copying image tags, model names or
  release-validation logs into guides. Keep dated incident evidence separate.
- Check local Markdown links/anchors and ensure every linked file is committed.
  Keep maintained guides in `docs/`; historical reports and local helpers belong
  in ignored `notes/`, not in links required by a fresh checkout.
- Retain only source-confirmed open issues; remove entries when fixes and their
  checks land. Do not carry forward old formatter/test counts as current facts.
- Keep personas, skills and cron prompts consistent when changing agent behavior.
  They are executable instructions, not spare documentation to reword casually.
