# Operations

[README](../README.md) · [Project map](project-context.md) · [Checks](development.md#checks)

Run commands from the repository root in Bash. They operate on the current
checkout; commit/push is not a prerequisite for deploying it. Never deploy and
prune the same node's store concurrently.

## Workstation access

Prerequisites: Nix with flakes, an authorized SSH identity, SOPS decryption access,
and Bitwarden access if refreshing secrets.

```bash
umask 077
nix develop
```

Shell startup installs formatting/scan hooks, generates `.cache/ssh/config`, and
may decrypt the encrypted `nodes` block into `.cache/nodes.json`. This is an
operator environment, not a side-effect-free inspection command. Direnv runs
the same shell hook when allowed.

| Target | Connection |
| --- | --- |
| `engineer-local` | Engineer LAN IP, SSH port 22 |
| `engineer-remote` | Encrypted Pangolin SSH resource host/port; disabled by default at the edge |
| `pangolin-remote` (alias `pangolin`) | VPS address, SSH port 22 |

There is no `pangolin-local`. Addresses and SSH user come from encrypted node
metadata. The shell uses `~/.ssh/$USER` as the operator identity; it does not use
a configurable identity path from that metadata.

If metadata is missing, `nix run .#bootstrap` decrypts just the node block. With no
age identity, it offers to derive one from `~/.ssh/$(hostname -s)`—a different
convention from runtime SSH. Re-enter the shell after bootstrapping metadata.
Use `nix run .#deploy -- status engineer-local` to test SSH; the standalone
`status` app only pings cached node IPs, even for its “remote” result.

### Kubernetes access

```bash
umask 077
eval "$(nix run .#kubeconfig -- engineer-local)"
kubectl config current-context
kubectl get nodes
k9s
```

This fetches the **cluster-admin** kubeconfig over SSH and caches it at
`.cache/kubeconfig/engineer.yaml`. LAN mode uses cached metadata without SOPS;
remote mode decrypts the full secret document to a temporary file to find the
API endpoint. `engineer-remote` also needs its public SSH resource temporarily
enabled. Protect existing cache-file permissions too; `umask` only affects new
files. Never paste kubeconfig or Secret contents into logs/chat.

## Secrets

Source: [secrets app](../nix/apps/secrets.nix),
[declarations](../secrets/default.nix), [recipient rules](../.sops.yaml).

```text
Bitwarden notes → ignored bitwarden/ plaintext → SOPS-encrypted secrets/secrets.yaml
                                                    ↓
                              host runtime secret files / Kubernetes templates
```

Bitwarden's `homelab-secrets` folder has one YAML note per top-level key; SSH keys
come from a separate folder. Edit those notes in Bitwarden; the app reads them,
it does not push edits back. Direct SOPS edits must also be reconciled there
before a later pull/sync overwrites them.

**Stop on any encryption error.** The current script copies plaintext over the
encrypted destination before encrypting it. Do not assume a failed command left
the old ciphertext intact. Ignoring `bitwarden/` is not filesystem access control.

For a normal refresh, after editing the secure source:

```bash
umask 077
nix run .#secrets -- pull
nix run .#secrets -- sync
sops filestatus secrets/secrets.yaml
```

Confirm the result reports encrypted before staging. Tighten existing plaintext
file permissions too; `umask` only protects newly created files.

Two different bootstrap commands:

| Command | Purpose |
| --- | --- |
| `nix run .#bootstrap` | Materialize local node connection metadata |
| `nix run .#secrets -- bootstrap engineer` | Add SOPS recipients and stage private install files under `.cache/extra-files/engineer` |

On a fresh workstation, `nix run .#secrets -- init` derives the local age identity
from the pulled **Engineer** SSH private key. Do not run it over an existing
identity you need to retain. Recipient additions do not rekey existing ciphertext
by default: review `.sops.yaml`, then explicitly run `nix run .#secrets -- rekey`.

| Host | Current runtime decryption identity |
| --- | --- |
| Engineer | `/root/.ssh/id_ed25519` |
| Pangolin | `/root/.ssh/theadministrator` |

Bootstrap stages named and compatibility keys for installation. Matching private
keys must exist before activation; adding public recipients alone is insufficient.
SOPS replacement is not full credential rotation: database accounts, completed
bootstrap Jobs, app restarts and external permissions may need coordinated work.

## Install a new machine

**Destructive: partitions disks, installs NixOS and reboots. The wrapper has no
install confirmation gate.** This is not the update procedure.

Before proceeding:

1. Check the target's SSH identity and hostname through an independent channel.
2. Review its exact disk device/partitions: [Engineer](../nodes/engineer/disko.nix)
   or [Pangolin](../nodes/pangolin/disk-config.nix). These are machine-specific.
3. Verify recoverable off-host data backups and staged SOPS keys. For a new site,
   complete [Pangolin/WireGuard provisioning](../nodes/engineer/bootstrapping.md).
4. Review Engineer's [initial account/SSH defaults](housekeeping-audit.md#access-and-secrets)
   before exposing a fresh installation.

For **one chosen host**, stage keys, review recipient changes, and rekey if needed:

```bash
nix run .#secrets -- bootstrap engineer
# After reviewing any recipient changes:
nix run .#secrets -- rekey
nix run .#deploy -- install engineer-local
```

For the VPS use `bootstrap pangolin` and `install pangolin-remote` instead. The
installer builds remotely and uses `.cache/extra-files/<node>` when present.
Per-node rescue/install images are also available:
`nix build .#engineer-install-iso` or `nix build .#pangolin-install-iso`.

## Update an existing machine

**GitLab:** follow the [staged upgrade guide](../workloads/namespace/cicd/apps/gitlab/UPGRADE.md)
before deploying the final chart-10 defaults over an older installation. Required
upgrade stops and the Redis restore/cutover cannot be skipped.

1. Review the diff and run [local checks](development.md#checks).
2. For stateful changes, complete the [data checklist](#data-and-recovery) first.
3. Activate **one target at a time**:

```bash
nix run .#deploy -- update engineer-local
# Or, for the VPS:
nix run .#deploy -- update pangolin-remote --low-cost
```

`update`/`switch` use nixos-rebuild-ng with both build and target host set to the
selected SSH target. `test` also performs live activation. `--low-cost` is accepted
only for update/switch/test and forwards `--max-jobs 1 --cores 1`. These are
scheduling limits, **not a CPU/RAM cap**, and do not alter an already-running build.
Do not start another deployment to “apply” the flag to one in progress.

After Engineer activation, with the correct kubeconfig:

```bash
kubectl -n kube-system get helmcharts
kubectl get pods -A
kubectl get pvc -A
ssh engineer-local 'systemctl --no-pager status k3s.service pangolin-kwg-blueprint-sync.service'
```

After VPS activation:

```bash
ssh pangolin-remote 'systemctl --no-pager status pangolin.service gerbil.service traefik.service livekit.service lk-jwt-service.service'
```

Inspect failed Helm Jobs/events, the changed app's rollout, logs and actual
behavior. Test the intended LAN/public path. A successful Nix switch is not proof
that charts reconciled, the whole-org blueprint synced, or a backend works.
For [SearXNG](../workloads/namespace/dashboard/apps/searxng/settings.nix), test a
real search in a fresh browser session; `/healthz` alone does not test engines.

## Store maintenance

```bash
nix run .#store-cleanup -- engineer-local --report
# Destructive to rollback history; prompts for the exact target:
nix run .#store-cleanup -- engineer-local --clean
# Also permits a service-interrupting reboot:
nix run .#store-cleanup -- engineer-local --clean --reboot
```

Use `pangolin-remote` for the VPS. **Never reboot through `engineer-remote`**:
startup blueprint sync disables its SSH resource. If a reboot completed but the
health wait failed, resolve the error and retry `--clean` alone.

Cleanup requires the selected system to be active and booted, SSH plus node-core
services healthy, and no unresolved newer generations after rollback. Unrelated
failed units warn. It keeps current + one previous system generation, refreshes
boot entries, garbage-collects and optimizes. Errors stop subsequent steps, not
undo completed ones. App/PVC data, user profiles and other GC roots are untouched.
Both hosts also have weekly automatic GC with 30-day retention; manual cleanup
does not change that policy.

## Data and recovery

The repository does **not** establish a complete off-host backup/restore system.
Before a reinstall or stateful upgrade, confirm where these copies exist and
verify an isolated restore—not merely that an archive can be listed.

| State | Protect together |
| --- | --- |
| PostgreSQL | Databases, roles/grants, migration state, app credentials and coordinated uploads/files |
| MinIO and GitLab | Objects/buckets, Git repositories, configuration and keys; GitLab depends on SQL, S3 and Redis |
| GitLab Redis | Full multi-part AOF directory/manifest and existing authentication Secret; preserve the old PVC during the verified copy/cutover |
| Application/media PVCs | Local-path contents and app keys; requested PVC size is not a disk quota or a backup |
| Pangolin | `/var/lib/pangolin`, organization/site identities, API and WG credentials, ACME state |
| Grafana/Kuma | SQLite/data plus keys; see [manual monitoring backups](monitoring-storage-backups.md) |
| Agents and research KB | Mutable `.hermes` profiles/OAuth, campaign state, authoritative KB/Git repository |
| Secret recovery | Bitwarden/SSH/SOPS identities stored securely outside the machines being recovered |

Grafana declares a 10 GiB Helm-owned PVC with `Recreate`; Kuma declares its existing
2 GiB PVC with `Recreate`. **Enabling persistence does not copy an older Grafana
`emptyDir`.** Check actual storage before replacing a legacy pod. Homarr board
JSON snapshots are not automatically imported by the Nix configuration.

For rollback after a database migration: stop writers, preserve evidence, and
restore compatible pre-upgrade data/files/keys before starting the old image.
Reverting image pins or selecting a NixOS generation alone does not reverse it.
Keep required PVC settings when reverting; do not accidentally return Grafana to
`emptyDir`. Removing an app requires an explicit resource/data/credential removal
plan, not just deleting its Nix import.
