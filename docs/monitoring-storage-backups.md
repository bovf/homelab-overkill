# Monitoring backups

[Operations](operations.md#data-and-recovery) · [Project map](project-context.md)

**Manual maintenance, not a read-only check:** these steps create temporary
containers/pods, stop Kuma briefly and write encrypted archives. They do not
configure scheduled backups and have not been run against production in this
documentation pass.

## Before you start

- Confirm the Kubernetes context, actual pod storage and database backends. These
  procedures require SQLite at Grafana's `/var/lib/grafana/grafana.db` and Kuma's
  `/app/data/kuma.db`. An external database needs its own consistent dump.
- Source declares Grafana's Helm-owned `kube-prometheus-stack-grafana` 10 GiB PVC
  and Kuma's `uptime-kuma` 2 GiB PVC, both with `Recreate`. See
  [Grafana values](../workloads/namespace/monitoring/apps/kube-prometheus-stack/helm.nix)
  and [Kuma values](../workloads/namespace/monitoring/apps/uptime-kuma/helm.nix).
- **If Grafana still uses `emptyDir`, do not replace/stop that pod before backup.**
  Enabling persistence does not migrate its data. Do not create an unrelated
  `grafana-data` claim; the configured chart does not reference it.
- Avoid configuration/plugin changes during snapshots. Preserve SOPS recovery
  identities and application encryption keys separately. Keep completed archives
  **off Engineer**; local-path storage is not protection from disk loss.

Use Bash with working `kubectl`, `age`, and Python 3.12+ for verification.

## Prepare a private backup directory

```bash
set -euo pipefail
umask 077
kubectl config current-context
kubectl get nodes
BACKUP="$HOME/Backups/homelab/$(date -u +%Y%m%dT%H%M%SZ)"
mkdir -p "$BACKUP"
BACKUP_IMAGE='python:3.13-alpine@sha256:7415fbc3c9e4979cc717d92377ab2bc7b2b4a2af1ac03cc52b5f3f88efedaf3a'
kubectl -n monitoring get deployment kube-prometheus-stack-grafana uptime-kuma \
  -o 'custom-columns=NAME:.metadata.name,IMAGES:.spec.template.spec.containers[*].image' \
  > "$BACKUP/running-images.txt"
```

`age -p` prompts for an encryption passphrase: store it in your password manager. Run each block separately and stop on errors; only a successful pipeline may promote a `.part` file. If running on engineer, copy the completed encrypted archives to a different machine **before** deployment.

## Grafana: online SQLite snapshot

Do not scale down/delete the current Grafana pod. Require exactly one matching pod, UID 472, and its existing `storage` volume. The temporary container below does not replace the pod.

```bash
GRAFANA_POD="$(kubectl -n monitoring get pods \
  -l app.kubernetes.io/instance=kube-prometheus-stack,app.kubernetes.io/name=grafana \
  -o jsonpath='{.items[*].metadata.name}')"
[[ "$GRAFANA_POD" =~ ^[a-z0-9][-a-z0-9]*$ ]]
kubectl -n monitoring exec "$GRAFANA_POD" -c grafana -- id
PROFILE="$(mktemp)"
printf '%s\n' '{"volumeMounts":[{"name":"storage","mountPath":"/source"}],"securityContext":{"runAsUser":472,"runAsGroup":472,"runAsNonRoot":true,"allowPrivilegeEscalation":false,"capabilities":{"drop":["ALL"]},"seccompProfile":{"type":"RuntimeDefault"}}}' > "$PROFILE"
kubectl -n monitoring debug "$GRAFANA_POD" --container=grafana-backup \
  --image="$BACKUP_IMAGE" --profile=restricted --custom="$PROFILE" \
  --attach=false -- sleep 3600
rm -- "$PROFILE"
kubectl -n monitoring wait "pod/$GRAFANA_POD" \
  --for='jsonpath={.status.ephemeralContainerStatuses[?(@.name=="grafana-backup")].state.running.startedAt}' \
  --timeout=180s
```

SQLite's online backup API produces the coherent database snapshot. Its connection is read-only; the mount allows normal SQLite WAL/shared-memory housekeeping. Other data files are archived alongside the snapshot, not alongside a raw copy of the live database/WAL.

```bash
kubectl -n monitoring exec -i "$GRAFANA_POD" -c grafana-backup -- python - <<'PY'
import contextlib, os, sqlite3, tarfile, time
from pathlib import Path
os.umask(0o077)
deadline = time.monotonic() + 120
def progress(*_):
    if time.monotonic() > deadline:
        raise TimeoutError("SQLite backup exceeded 120 seconds")
with contextlib.closing(sqlite3.connect("file:/source/grafana.db?mode=ro", uri=True)) as src, contextlib.closing(sqlite3.connect("/tmp/grafana.db")) as dst:
    src.backup(dst, pages=256, progress=progress, sleep=0.1)
    assert dst.execute("PRAGMA integrity_check").fetchone() == ("ok",)
with tarfile.open("/tmp/grafana.tar.gz", "w:gz") as archive:
    for path in Path("/source").iterdir():
        if path.name not in {"grafana.db", "grafana.db-wal", "grafana.db-shm", "grafana.db-journal"}:
            archive.add(path, arcname=path.name)
    archive.add("/tmp/grafana.db", arcname="grafana.db")
print("Grafana snapshot integrity: ok")
PY
kubectl -n monitoring exec "$GRAFANA_POD" -c grafana-backup -- cat /tmp/grafana.tar.gz \
  | age -p -o "$BACKUP/grafana.tar.gz.age.part"
mv -- "$BACKUP/grafana.tar.gz.age.part" "$BACKUP/grafana.tar.gz.age"
age -d "$BACKUP/grafana.tar.gz.age" | gzip -t
```

The temporary container exits after an hour; its record remains until the pod is
replaced. If retrying, reuse the running backup container or choose a new name.
Do not delete Grafana to clean it up.

## Kuma: stopped-writer PVC archive

Confirm the backend without printing database credentials:

```bash
KUMA_POD="$(kubectl -n monitoring get pods \
  -l app.kubernetes.io/name=uptime-kuma,app.kubernetes.io/instance=uptime-kuma \
  -o jsonpath='{.items[*].metadata.name}')"
[[ "$KUMA_POD" =~ ^[a-z0-9][-a-z0-9]*$ ]]
kubectl -n monitoring exec "$KUMA_POD" -c main -- node -e \
  'console.log(JSON.parse(require("fs").readFileSync("/app/data/db-config.json", "utf8")).type)'
```

Continue only for `sqlite`. Prepare a read-only helper first; this does not stop Kuma. Its RWO local-path volume can be mounted by another pod on the same node.

```bash
kubectl -n monitoring create -f - <<YAML
apiVersion: v1
kind: Pod
metadata:
  name: kuma-backup
  namespace: monitoring
spec:
  restartPolicy: Never
  automountServiceAccountToken: false
  containers:
    - name: backup
      image: $BACKUP_IMAGE
      command: ["sleep", "3600"]
      securityContext:
        runAsUser: 0
        allowPrivilegeEscalation: false
        capabilities:
          drop: ["ALL"]
          add: ["DAC_OVERRIDE"]
      volumeMounts:
        - name: data
          mountPath: /data
          readOnly: true
  volumes:
    - name: data
      persistentVolumeClaim:
        claimName: uptime-kuma
        readOnly: true
YAML
kubectl -n monitoring wait pod/kuma-backup --for=condition=Ready --timeout=180s
KUMA_REPLICAS="$(kubectl -n monitoring get deployment uptime-kuma -o jsonpath='{.spec.replicas}')"
[[ "$KUMA_REPLICAS" == "1" ]]
kubectl -n monitoring scale deployment uptime-kuma --replicas=0
kubectl -n monitoring wait "pod/$KUMA_POD" --for=delete --timeout=180s
[[ -z "$(kubectl -n monitoring get pods -l app.kubernetes.io/name=uptime-kuma -o jsonpath='{.items[*].metadata.name}')" ]]
kubectl -n monitoring exec kuma-backup -- tar -C /data -czf - . \
  | age -p -o "$BACKUP/kuma.tar.gz.age.part"
mv -- "$BACKUP/kuma.tar.gz.age.part" "$BACKUP/kuma.tar.gz.age"
age -d "$BACKUP/kuma.tar.gz.age" | gzip -t
kubectl -n monitoring delete pod kuma-backup --wait=true
kubectl -n monitoring scale deployment uptime-kuma --replicas="$KUMA_REPLICAS"
kubectl -n monitoring rollout status deployment/uptime-kuma --timeout=180s
```

If anything fails while Kuma is stopped, delete only `pod/kuma-backup` and scale `deployment/uptime-kuma` back to its original one replica before investigating. Never delete its PVC. Do not deploy against an incomplete backup, and stop if another controller restarts Kuma during the archive.

## Verify the archives

Extract each archive into private scratch space, not a live app directory. The
`data` extraction filter rejects unsafe paths. Remove plaintext after checking:

```bash
for APP in grafana kuma; do
  VERIFY="$(mktemp -d)"
  age -d "$BACKUP/$APP.tar.gz.age" | python3 -c \
    'import sys,tarfile; tarfile.open(fileobj=sys.stdin.buffer,mode="r|gz").extractall(sys.argv[1],filter="data")' "$VERIFY"
  python3 - "$VERIFY/$APP.db" <<'PY'
import sqlite3, sys
from pathlib import Path
db = sqlite3.connect(Path(sys.argv[1]).as_uri() + "?mode=ro", uri=True)
try:
    assert db.execute("PRAGMA integrity_check").fetchone() == ("ok",)
finally:
    db.close()
print("Restored SQLite integrity: ok")
PY
  rm -rf -- "$VERIFY"
done
(cd "$BACKUP" && sha256sum *.age > SHA256SUMS && sha256sum -c SHA256SUMS)
```

These checks verify decryption, archive extraction and SQLite integrity, not a full application restore or external credential validity. If verification fails, keep the encrypted backup and secure/remove the private scratch directory before retrying. For a real restore after Grafana's PVC exists, stop its writers first and restore into an empty destination with UID/GID 472; do not overlay an old database onto newer WAL files. Keep the PVC settings when rolling an application image back—an image/configuration rollback does not reverse database migrations. A backup is not automatically restored by Helm.
