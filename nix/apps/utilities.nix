{ nixpkgs, ... }:

{
  mkStatusApp = system: enabledNodes: {
    type = "app";
    program = toString ((import nixpkgs { inherit system; }).writeShellScript "status" ''
      set -euo pipefail

      # Tell sops where the age key lives
      export SOPS_AGE_KEY_FILE="$HOME/.config/sops/age/keys.txt"

      # Try to decrypt secrets/secrets.yaml
      SSH_SECRETS_FILE=""
      if [ -f "secrets/secrets.yaml" ] && command -v sops >/dev/null 2>&1; then
        tmpdir="${TMPDIR:-/tmp}"
        SSH_SECRETS_FILE="$(mktemp "$tmpdir/dobryops-status-secrets.XXXXXX")"
        if sops --decrypt secrets/secrets.yaml >"$SSH_SECRETS_FILE" 2>/dev/null; then
          echo "Decrypted secrets for status check" >&2
        else
          echo "Failed to decrypt secrets/secrets.yaml (checking local IPs only)" >&2
          rm -f "$SSH_SECRETS_FILE"
          SSH_SECRETS_FILE=""
        fi
      fi

      # Helper: fetch secret or return default
      get_secret() {
        key="$1"
        default="$2"
        if [ -z "$SSH_SECRETS_FILE" ] || ! command -v yq >/dev/null 2>&1; then
          printf "%s" "$default"
          return
        fi
        value="$(yq -r ".$key // \"\"" "$SSH_SECRETS_FILE" 2>/dev/null || true)"
        if [ -n "$value" ] && [ "$value" != "null" ]; then
          printf "%s" "$value"
        else
          printf "%s" "$default"
        fi
      }

      echo "homelab status"
      echo ""

      ${nixpkgs.lib.concatStringsSep "\n" (nixpkgs.lib.mapAttrsToList (name: node:
        let
          localPort = toString (node.localPort or 22);
          remoteHostKey = node.remoteHostSecretKey or "";
          remotePortKey = node.remotePortSecretKey or "";
        in ''
          # ${name}
          {
            ip="${node.ip}"
            port="${localPort}"

            # Always ping local if IP is configured
            if [ -n "$ip" ]; then
              echo -n "${name} (local: $ip:$port): "
              if ping -c 1 -W 3 "$ip" >/dev/null 2>&1; then
                echo "online"
              else
                echo "offline"
              fi
            fi

            # Ping remote only if secrets provide different host/port
            default_remote_host="$ip"
            default_remote_port="$port"
            remote_host="$(get_secret "${remoteHostKey}" "$default_remote_host")"
            remote_port="$(get_secret "${remotePortKey}" "$default_remote_port")"

            if [ -n "$remote_host" ]; then
              echo -n " | remote ($remote_host:$remote_port): "
              if ping -c 1 -W 3 "$remote_host" >/dev/null 2>&1; then
                echo "online"
              else
                echo "offline"
              fi
            fi
          }
        ''
      ) enabledNodes)}

      # Clean up decrypted secrets
      if [ -n "$SSH_SECRETS_FILE" ] && [ -f "$SSH_SECRETS_FILE" ]; then
        rm -f "$SSH_SECRETS_FILE"
      fi
    '');
  };
}
