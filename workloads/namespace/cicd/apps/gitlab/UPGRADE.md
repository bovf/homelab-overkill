# GitLab 19.5 and native MCP rollout

Source target, checked against GitLab's chart index on **2026-11-01**:
**chart 10.5.4 / GitLab 19.5.3**. The separate Nix runner uses chart 0.94.2 /
Runner 19.5.2. These are repository declarations, not deployed-version claims.

**Do not deploy the final defaults directly over GitLab 18.5.1.** This is a
stateful, maintenance-window upgrade. Complete the stops below and migrate Redis
before installing chart 10. Run these commands only in an approved maintenance
window, and check the live version first; do not replay older stops against an
already-upgraded instance.

## Required stops

Temporarily set these options in `nodes/engineer/default.nix` before each
explicitly authorized deployment:

```nix
workloads.gitlab = {
  chartVersion = "9.5.7";
  externalRedis = false;
};
```

| Phase | Chart | GitLab | `externalRedis` |
|---|---|---|---|
| Optional backup-configuration preparation, no version change | 9.5.1 | 18.5.1 | false |
| Patch the current upgrade stop | 9.5.7 | 18.5.7 | false |
| Required stop | 9.8.12 | 18.8.11 | false |
| Required stop | 9.11.16 | 18.11.14 | false |
| Separate Redis cutover, **after restoration below** | 9.11.16 | 18.11.14 | true |
| Required stop | 10.2.10 | 19.2.10 | true |
| Final target | 10.5.4 | 19.5.3 | true |

Use the repository's deploy app, not an independent `helm upgrade` whose values
would diverge from the k3s HelmChart:

```bash
nix run .#deploy -- update engineer-local
```

At **every** stop:

1. Inspect the k3s Helm installation/upgrade Job and GitLab migration Jobs; require
   success. A successful NixOS activation does not establish Helm success.
2. Wait for all batched background migrations to finish under **Admin > Monitoring
   > Background migrations** (`/admin/background_migrations`). Do not advance with
   active, pending, or failed migrations. Consult the version-specific upgrade notes.
3. Check application readiness, login, repository clone/push, Sidekiq, runners,
   CI artifacts/LFS, and registry push/pull. Confirm actual application versions.
4. Refresh verified backups before proceeding. Do not run deployments concurrently.

Remove the temporary options only after the final phase is reached. Defaults
then continue to select chart 10.5.4 with external Redis. Do not disable upstream
upgrade checks, skip migrations, or treat an ordinary Nix rollback as a database
rollback. This single-node deployment is **not** a zero-downtime upgrade.

## Preflight and backups

Before any upgrade, verify the actual Helm release, Kubernetes namespace, versions,
PVCs, Secret references, replicas, available disk space, and restore procedure.
The expected release is `gitlab` in `cicd`, with HelmChart `gitlab` in `kube-system`.
Do not infer actual state from a source pin.

Preserve off-host, with restrictive permissions/encryption:

- A consistent PostgreSQL backup and GitLab repositories/Gitaly data.
- GitLab object-store data in MinIO, including registry blobs and backup archives.
- Generated Kubernetes credentials, especially `gitlab-rails-secret` and
  `gitlab-redis-secret`. These are not replaced by the SOPS file or initial root
  password. Keep encryption keys separately from database backups.
- The full Redis persistence directory, including **all** AOF files and its
  manifest, plus the existing Redis authentication Secret.
- Helm values/manifests, running image versions, deployment replica counts, and
  the pre-upgrade source revision. These exports can contain secrets; do not put
  them in Git, chat, ordinary logs, or a public artifact.

GitLab's Toolbox backup connection is now wired to the already declared
`gitlab-backups` and `gitlab-tmp` MinIO buckets, using the existing GitLab MinIO
credentials in an activation-rendered Secret. This configures backup capability;
it does **not** take a backup, enable a schedule, or provide an off-host copy.
Verify the buckets, permissions, free space, backup archive, and an isolated restore.

If the current Toolbox cannot back up, prepare this connection at the **existing
chart 9.5.1**, or use a proven independent backup procedure before changing versions.
Even that configuration-only deployment can restart pods; do not proceed without
recoverable data. Once configured, the standard chart command is:

```bash
kubectl -n cicd exec deployment/gitlab-toolbox -c toolbox -- backup-utility
```

Verify the actual Toolbox name first. Copy the archive off Engineer; MinIO on the
same machine is not disaster recovery. Redis and Rails secrets require separate
backup handling. Inspect `:skipped` in `backup_information.yml`: a successful
Toolbox backup can omit object-storage components, including the registry. Back
up those MinIO objects and required bucket/format metadata separately and verify
an isolated restore. Preserve a recovery copy of required container images if
they are available only in the node's cache. An archive listing alone is not a
restore test.

Compatibility checks:

- GitLab 19 requires PostgreSQL 17 or later. Source declares PostgreSQL 17.10;
  verify the running server and required extensions (`amcheck`, `btree_gist`,
  `pg_trgm`, `plpgsql`). The versioned GitLab database init Job ensures these
  extensions without rotating an existing role password. No PostgreSQL major
  upgrade is included here.
- Chart 10 removes bundled Redis, PostgreSQL, and MinIO. PostgreSQL and MinIO
  already run separately; Redis is migrated below.
- Existing Traefik Ingress routing is retained. Envoy installation, Gateway API,
  and Gateway-managed certificate issuance are explicitly disabled.
- The registry S3 driver moves to the AWS SDK v2 implementation. The existing
  MinIO endpoint includes its HTTP scheme and uses path-style addressing. Test
  registry uploads, downloads **and deletions** at the major-version stop; consult
  the GitLab 19 notes if MinIO rejects checksum headers. Do not change buckets or
  discard registry data to work around an error.
- GitLab 19.5 can migrate Duo checkpoint data. If present, check the database space
  needed by that migration and wait for it to finish as well.

## Redis cutover at GitLab 18.11.14

The new workload uses Redis **7.2.17**, a supported 7.2 patch release, with AOF,
`noeviction`, a single replica and `Recreate`. Its private Service is
`gitlab-redis-external.cicd.svc.cluster.local:6379`. A Redis exporter retains a
metrics endpoint on port 9121; scrape discovery now uses the new Service name.

It reuses **`cicd/gitlab-redis-secret`, key `secret`**, without generating or rotating
credentials. The old chart's expected PVC is `redis-data-gitlab-redis-master-0`.
The new PVC is **`gitlab-redis-external`**, requested at 8 GiB. Verify these names,
data-file ownership (UID/GID 1001; the PVC root can be root-owned), capacity and the actual AOF layout first; stop and adapt the plan if
live state differs. The old writable PVC is never mounted by the new server.

Keep `chartVersion = "9.11.16"; externalRedis = false;` throughout preparation.
No concurrent rebuilds, Helm operations, autoscaling changes or GitLab writes may
occur during this maintenance window.

1. Pause new CI jobs and writes, let background migrations finish, and record the
   original application replica counts. Gracefully stop Redis clients, including
   Webservice, Sidekiq, GitLab Shell, KAS and Mailroom where installed. For the
   chart's standard labels:

   ```bash
   clients='release=gitlab,app in (webservice,sidekiq,gitlab-shell,kas,mailroom)'
   kubectl -n cicd scale deployment -l "$clients" --replicas=0
   kubectl -n cicd wait --for=delete pod -l "$clients" --timeout=10m
   ```

   Verify all clients are quiescent, including any separately configured clients.
   Record Redis keyspace/queue state without printing its password. Take the
   consistent backups described above.

2. Stop the old Redis cleanly and wait for its Pod to disappear:

   ```bash
   kubectl -n cicd scale statefulset/gitlab-redis-master --replicas=0
   kubectl -n cicd wait --for=delete pod/gitlab-redis-master-0 --timeout=5m
   ```

   Preserve the old PVC and Secret. Never run two Redis writers on one volume.

3. After verifying the source claim, create this temporary restore Pod and new
   PVC. Save/apply this YAML outside the repository. The source is mounted
   read-only. Kubernetes schedules it with the source local-path PV; the new
   local-path claim binds on that same node. Do not wait for the PVC to bind
   before creating its first consumer.

   ```yaml
   apiVersion: v1
   kind: PersistentVolumeClaim
   metadata:
     name: gitlab-redis-external
     namespace: cicd
   spec:
     accessModes: [ReadWriteOnce]
     storageClassName: local-path
     resources:
       requests:
         storage: 8Gi
   ---
   apiVersion: v1
   kind: Pod
   metadata:
     name: gitlab-redis-restore
     namespace: cicd
   spec:
     restartPolicy: Never
     automountServiceAccountToken: false
     securityContext:
       runAsUser: 1001
       runAsGroup: 1001
       fsGroup: 1001
     containers:
       - name: restore
         image: docker.io/library/redis:7.2.17-bookworm@sha256:0312984fbfeb2ff1d4382ecef45b50e7d65478a6a58cf12ce28d6de7a4142e45
         command: [sh, -ec, "sleep infinity"]
         volumeMounts:
           - name: source
             mountPath: /source
             readOnly: true
           - name: target
             mountPath: /target
     volumes:
       - name: source
         persistentVolumeClaim:
           claimName: redis-data-gitlab-redis-master-0
           readOnly: true
       - name: target
         persistentVolumeClaim:
           claimName: gitlab-redis-external
   ```

4. Wait for the restore Pod, copy into the **empty** destination, verify file
   checksums and the multi-part AOF, then write the startup marker **last**:

   ```bash
   kubectl -n cicd wait --for=condition=Ready pod/gitlab-redis-restore --timeout=5m
   kubectl -n cicd exec gitlab-redis-restore -- sh -ec '
     test -s /source/appendonlydir/appendonly.aof.manifest
     test -z "$(find /target -mindepth 1 -maxdepth 1 -print -quit)"
     cp -R /source/. /target/
     (cd /source && find . -type f -exec sha256sum {} \;) > /tmp/redis-files.sha256
     (cd /target && sha256sum -c /tmp/redis-files.sha256)
     redis-check-aof /target/appendonlydir/appendonly.aof.manifest
     printf "Verified copy from stopped GitLab Redis at %s\n" "$(date -u +%FT%TZ)" > /target/.homelab-redis-restored
   '
   kubectl -n cicd delete pod/gitlab-redis-restore --wait=true
   ```

   **Stop on any failure.** Do not use `redis-check-aof --fix` on the only copy or
   create the marker to bypass an error. A failed partial copy requires inspection
   and a deliberate retry; this command will not overwrite a non-empty destination.
   The new server refuses to start without both the marker and an AOF manifest.

5. Keep chart **9.11.16**, change `externalRedis = true`, and deploy Engineer.
   This starts the separate Redis workload, switches GitLab's connection, and
   disables the old bundled Redis. Confirm authenticated Redis readiness, expected
   keyspace/queue contents, and the GitLab migration/Helm Jobs. Restore any
   maintenance-scaled application replica counts from your record if Helm has not
   restored them; require nonzero ready replicas and working application checks.

6. Keep the old PVC and off-host backup until the full rollout is verified. It is
   no longer current once the new server accepts writes; do not switch back to it
   casually. Only then proceed to chart 10.2.10 and finally 10.5.4.

## Native MCP authorization

GitLab **19.5** makes the native MCP server generally available on Free, Premium
and Ultimate tiers. Instance MCP access is **on by default**, including on upgrade,
unless an administrator disabled it. Do not add the removed `mcp_server` or
`oauth_dynamic_client_registration` experiment flags, a proxy MCP server, or a Duo
license requirement for the standard MCP tools.

After the final rollout:

1. Confirm the running GitLab version is 19.5.3.
2. In **Admin > Settings > General > Visibility and access controls > MCP client
   access**, verify **Allow connection to GitLab** is selected. If an administrator
   previously disabled it, enable it there explicitly; this branch does not
   overwrite a stored administrator decision through an unverified Rails hook.
3. Use the existing client's direct HTTP endpoint:

   ```text
   https://gitlab.dobryops.com/api/v4/mcp
   ```

   GitLab is already routed without Pangolin SSO, so its OAuth flow is not replaced
   by a Pangolin login. No extra hostname, Kubernetes port, or public exposure is
   needed for MCP.
4. Complete client OAuth authorization in the browser, reviewing the requested
   `mcp` scope. Standard legacy personal/project/group tokens with `api` scope do
   not substitute for this OAuth permission. Do not paste credentials into chat.
5. Verify MCP initialization, tool discovery and a harmless read against an
   authorized project. A reachable URL alone does not prove OAuth or MCP works.

Local source validation does not authorize a live deployment or sign in an MCP
client. Obtain maintenance approval before running the rollout; client OAuth
consent remains a browser action. Tool authorization follows the GitLab user's
permissions; only use tools on content you trust.

## Local validation and recovery

The checks use evaluated placeholders, synthetic hosts/credentials, and a fake
Redis executable; they do not decrypt SOPS, contact Kubernetes or deploy anything:

```bash
python3 nix/apps/check-gitlab.py
```

For full offline rendering after downloading the **public** chart archives:

```bash
charts=$(mktemp -d)
for version in 9.5.1 9.5.7 9.8.12 9.11.16 10.2.10 10.5.4; do
  helm pull gitlab --repo https://charts.gitlab.io --version "$version" \
    --untar --untardir "$charts/$version"
done
python3 nix/apps/check-gitlab.py --charts-dir "$charts"
```

The checker covers both Redis modes at 18.11, chart/application mappings,
Traefik routing, external-Service selector compatibility, backup Secret wiring,
credential escaping and refusal to start an un-restored Redis volume. Source
validation does not establish live upgrade, backup or restore success.

If a phase fails, stop at that phase and diagnose; do not jump ahead or disable
upgrade checks. Recovery after database migrations requires the matching GitLab
version and a consistent database/repository/object-store/Redis backup with the
original Rails secrets. A lower image pin, retained Redis PVC, or NixOS generation
alone is not a safe rollback plan.

## Official references

- [Chart/version mappings](https://docs.gitlab.com/charts/installation/version_mappings/)
- [Required upgrade stops](https://docs.gitlab.com/update/upgrade_paths/)
- [GitLab 18 upgrade notes](https://docs.gitlab.com/update/versions/gitlab_18_changes/)
- [GitLab 19 upgrade notes](https://docs.gitlab.com/update/versions/gitlab_19_changes/)
- [Chart 10 changes](https://docs.gitlab.com/charts/releases/10_0/)
- [External Redis](https://docs.gitlab.com/charts/advanced/external-redis/)
- [External backup object storage](https://docs.gitlab.com/charts/advanced/external-object-storage/#backups)
- [Helm backup procedure](https://docs.gitlab.com/charts/backup-restore/backup/)
- [Native MCP](https://docs.gitlab.com/user/model_context_protocol/mcp_server/)
- [Instance MCP access](https://docs.gitlab.com/administration/settings/visibility_and_access_controls/#allow-access-to-the-mcp-server)
