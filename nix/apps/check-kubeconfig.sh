#!/usr/bin/env bash
# Hermetic local/remote secret-access check: fake SSH, SOPS and credentials only.
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/../.."
system="$(nix eval --impure --raw --expr builtins.currentSystem)"
nix run --offline --no-write-lock-file .#kubeconfig -- help >/dev/null 2>&1
app="$(nix eval --offline --no-write-lock-file --raw ".#apps.$system.kubeconfig.program")"

umask 077
scratch="$(mktemp -d)"
trap 'rm -rf -- "$scratch"' EXIT
mkdir -p "$scratch/bin" "$scratch/.cache" "$scratch/secrets"
printf '%s\n' '{"engineer":{"ip":"192.0.2.10"}}' >"$scratch/.cache/nodes.json"
printf '%s\n' 'synthetic test input' >"$scratch/secrets/secrets.yaml"
cat >"$scratch/bin/sops" <<'SH'
#!/usr/bin/env bash
set -euo pipefail
: >"$TMPDIR/sops-called"
printf '%s\n' '{"pangolin":{"resources":{"engineer_k8s_api":{"domain":"api.example.invalid","port":6443}}}}'
SH
cat >"$scratch/bin/ssh" <<'SH'
#!/usr/bin/env bash
set -euo pipefail
[[ $# == 3 && ($1 == engineer-local || $1 == engineer-remote) && $2 == cat && $3 == /etc/rancher/k3s/k3s.yaml ]]
printf '%s\n' 'apiVersion: v1' 'kind: Config' 'clusters:' '  - name: fixture' '    cluster:' '      server: https://127.0.0.1:6443'
SH
chmod +x "$scratch/bin/ssh" "$scratch/bin/sops"

(
  # Exported shell functions must not override the fake executables.
  unset -f ssh sops 2>/dev/null || true
  export PATH="$scratch/bin:$PATH" TMPDIR="$scratch"
  cd "$scratch"
  "$app" engineer-local >local-export.txt
  [[ ! -e sops-called ]]
  grep -q 'https://192.0.2.10:6443' .cache/kubeconfig/engineer.yaml
  [[ "$(<local-export.txt)" == "export KUBECONFIG=$scratch/.cache/kubeconfig/engineer.yaml" ]]

  "$app" engineer-remote >remote-export.txt
  [[ -f sops-called ]]
  grep -q 'https://api.example.invalid:6443' .cache/kubeconfig/engineer.yaml
  [[ -z "$(find . -maxdepth 1 -name 'dobryops-kubeconfig-secrets.*' -print)" ]]
)
printf '%s\n' 'PASS: local skips SOPS; remote still uses it; synthetic SSH only.'
