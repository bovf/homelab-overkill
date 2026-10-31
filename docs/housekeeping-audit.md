# Known issues

[README](../README.md) · [Operations](operations.md) · [Development](development.md)

Source cross-check against `80ed1ba` (2026-10-31). These are remaining code
limitations, not a live incident report or a claim about existing credentials,
permissions or backups. No runtime fixes are included in this documentation pass.

## Access and secrets

- **Secret encryption is not atomic.** `sync`/`encrypt` and first-time bootstrap
  copy plaintext to the tracked destination before SOPS succeeds. A failure can
  leave plaintext there. Encrypt to a restrictive temporary file and replace only
  after success. [Source](../nix/apps/secrets.nix)
- **Some private outputs inherit caller permissions.** Secret exports and cached
  kubeconfig writes lack consistent permission repair. Use `umask 077`, check
  existing files, and keep these directories private; ignore rules are not access
  control. [Secrets](../nix/apps/secrets.nix), [kubeconfig](../nix/apps/kubeconfig.nix)
- **Remote kubeconfig decrypts more than needed.** It uses a full-document
  temporary plaintext file and selected cleanup paths rather than an exit trap.
  LAN mode now skips SOPS; targeted extraction is still needed for remote mode.
  [Source](../nix/apps/kubeconfig.nix)
- **Engineer has permissive fresh-install SSH defaults.** A fixed initial account
  password, password authentication and root login are configured. Harden the
  provisioning configuration before exposing a new install; source alone does
  not establish an existing account's password. [Users](../common/users.nix),
  [SSH](../common/services.nix)
- **Administrator network metadata is public source.** The VPS guards still have
  a plaintext admin-IP TODO. Moving it later will not remove Git-history copies.
  [Source](../nodes/pangolin/guards.nix)

## Tooling and validation

- **The update helper can hide a failed build.** `mapfile < <(nix build ...)`
  does not propagate the producer's failure; no output returns success. Check
  each real build result independently until this is fixed.
  [Source](../nix/apps/update.nix)
- **TruffleHog execution failures can look clean.** The wrapper discards stderr
  and ignores the exit code, then counts output findings. An empty failed run is
  not evidence of a clean scan. [Source](../nix/apps/scan.nix)
- **Normal changes lack a CI validation gate.** The pipeline updates/caches or
  mirrors, but does not validate ordinary merge requests. Local formatting and
  focused checks exist; they are not wired as flake `checks` or general CI jobs.
  [CI](../.gitlab-ci.yml), [check commands](development.md#checks)
- **`status` does not validate remote SSH.** It pings cached node IPs and ignores
  the remote tunnel port. Prefer `deploy status <target>` for SSH reachability.
  [Source](../nix/apps/utilities.nix)
- **Installation has no wrapper confirmation gate.** It directly invokes the
  destructive installer. Manually verify the target and disk layout first.
  [Source](../nix/apps/deploy.nix)

## Workloads and stored data

- **SQL bootstrap/rotation is uneven.** GitLab, ezBookkeeping, Synapse and
  SparkyFitness Jobs have direct password interpolation and/or omit
  `ON_ERROR_STOP`; create-only role logic does not rotate existing passwords.
  Reuse RomM's checked, quoted variable pattern and test reruns with synthetic
  credentials. [SQL Jobs](../workloads/namespace/database/apps/postgresql/)
- **Bootstrap is not continuous reconciliation.** Fixed-name completed Jobs do
  not rerun after Secret/ConfigMap changes. Kuma requires a version bump for
  monitor-definition changes; the KB viewer copies its SSH key at container
  startup. Coordinate rotation and consumer restarts explicitly.
  [Kuma](../workloads/namespace/monitoring/apps/uptime-kuma/init-job.nix),
  [viewer](../workloads/namespace/knowledgebase/apps/ms-researcher-kb/helm.nix)
- **PVC metrics can conceal partial scans.** Individual `du` errors are swallowed
  while freshness advances and the error counter is unchanged.
  [Exporter](../workloads/namespace/monitoring/apps/local-path-du-exporter/exporter.py)
- **Loki's stated retention is not proof of deletion.** The values set a retention
  period but do not explicitly enable compactor retention/delete-request storage.
  Inspect rendered/effective configuration before relying on a storage bound.
  [Source](../workloads/namespace/monitoring/apps/loki/helm.nix)
- **Some dependencies are still mutable.** Examples include `busybox:latest`,
  the CI aggregator image, the KB publisher and startup package installation.
  `flake.lock` does not pin those paths. [Attic](../workloads/namespace/proxy/apps/attic-cache/deployment.nix),
  [Newt](../workloads/namespace/cicd/apps/newt/cronjob.nix),
  [viewer](../workloads/namespace/knowledgebase/apps/ms-researcher-kb/helm.nix)
- **KB availability is not freshness or privacy.** A placeholder/stale export can
  pass HTTP readiness. The viewer publishes all pages and raw `/kb/`, shares the
  writer's SSH-key setting, and its initial 30-second redirect can override reader
  navigation. Check publication markers, access boundaries and key permissions.
  [Source](../workloads/namespace/knowledgebase/apps/ms-researcher-kb/helm.nix)

Backup coverage, master-enable flags and app removal also have explicit limits;
see [data/recovery](operations.md#data-and-recovery) and
[deployment flow](project-context.md#hosts-and-deployment-flow). No complete
restore or live permission audit was performed here.

## Before re-enabling agents

MS Researcher and KotH DM remain disabled. Preserve their data and address these
issues before enabling their automation:

- **Research Git sync stops on a clean index**, so previously failed pushes and
  remote-only updates are not retried. Make only the commit conditional, not
  synchronization. [Source](../common/ms-researcher.nix)
- **RSS cleanup's example has unsafe containment and stale date traversal.** It
  uses string-prefix containment and scans legacy `YYYY_MM_DD` children, not its
  promised V2 nested dates. Fix/test against disposable trees before any deletion.
  [Source](../common/ms-researcher-skills/kb-rss-cleanup/SKILL.md)
- **Character rename can overwrite another character** through the generic field
  updater. Disallow identity changes there; retain collision-safe atomic saves.
  [Source](../common/mcps/character-sheets/src/koth_mcp_character_sheets/server.py)
- **Dice parsing does not validate the full expression**, and campaign prompts
  disagree about player rolls/initiative. Align the parser, skills and persona.
  Research prompts also retain legacy path/hosting wording.
  [Dice](../common/mcps/dice-roller/src/koth_mcp_dice_roller/server.py),
  [campaign skills](../common/koth-dm-skills/), [research prompts](../common/ms-researcher-cron/)

Close entries when the implementing change and its verification land. Do not
turn a source limitation into an unsupported claim about production health.
