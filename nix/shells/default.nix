{ pkgs, enabledNodes, ... }:

let
  sshWrapper = pkgs.writeShellScriptBin "ssh" ''
    set -euo pipefail
    if [ -n "''${SSH_CONFIG_FILE:-}" ]; then
      exec ${pkgs.openssh}/bin/ssh -F "$SSH_CONFIG_FILE" "$@"
    else
      exec ${pkgs.openssh}/bin/ssh "$@"
    fi
  '';

in
{
  default = pkgs.mkShell {
    packages = [
      sshWrapper
    ] ++ (with pkgs; [
      kubectl kubernetes-helm k9s sops age ssh-to-age bitwarden-cli jq yq-go
      curl wget git vim nixos-anywhere nixos-rebuild-ng
    ] ++ lib.optionals stdenv.isLinux [ iproute2 ]);

    shellHook = ''
      set -euo pipefail

      export SOPS_AGE_KEY_FILE="$HOME/.config/sops/age/keys.txt"

      SSH_CONFIG_DIR="$PWD/.cache/ssh"
      mkdir -p "$SSH_CONFIG_DIR"
      export SSH_CONFIG_FILE="$SSH_CONFIG_DIR/config"
      export NIX_SSHOPTS="-F $SSH_CONFIG_FILE"

      {
        if [ -f "$HOME/.ssh/config" ]; then
          echo "Include $HOME/.ssh/config"
          echo
        fi
        echo "# === DobryOps Homelab Nodes ==="
        echo
      } >"$SSH_CONFIG_FILE"

      SSH_SECRETS_FILE=""
      if [ -f "secrets/secrets.yaml" ] && command -v sops >/dev/null 2>&1; then
        tmpdir="$TMPDIR"
        if [ -z "$tmpdir" ]; then
          tmpdir="/tmp"
        fi
        SSH_SECRETS_FILE="$(mktemp "$tmpdir/dobryops-ssh-secrets.XXXXXX")"
        if sops --decrypt secrets/secrets.yaml >"$SSH_SECRETS_FILE" 2>/dev/null; then
          echo "Decrypted SSH secrets from sops" >&2
        else
          echo "Failed to decrypt secrets/secrets.yaml (using defaults)" >&2
          rm -f "$SSH_SECRETS_FILE"
          SSH_SECRETS_FILE=""
        fi
      fi

      # Helper: fetch secret or return default
      get_secret() {
        local key="$1"
        local default="$2"
        if [ -z "$SSH_SECRETS_FILE" ] || ! command -v yq >/dev/null 2>&1; then
          printf "%s" "$default"
          return
        fi
        local value
        value="$(yq -r ".$key // \"\"" "$SSH_SECRETS_FILE" 2>/dev/null || true)"
        if [ -n "$value" ] && [ "$value" != "null" ]; then
          printf "%s" "$value"
        else
          printf "%s" "$default"
        fi
      }

      # Build node summary lines in a bash variable
      NODE_SUMMARIES=""

      # Generate per-node SSH config from decrypted secrets
      ${pkgs.lib.concatStringsSep "\n" (pkgs.lib.mapAttrsToList (name: node:
        let
          localPort = toString (node.localPort or 22);
          remoteHostKey = node.remoteHostSecretKey or "";
          remotePortKey = node.remotePortSecretKey or "";
          sshUser = node.sshUser or "root";
          # Candidate identity files baked in at Nix eval time; resolved at runtime
          configuredIdentity = node.identityFile or "";
        in ''
          # ${name}
          {
            local local_ip="${node.ip}"
            local local_port="${localPort}"

            local remote_host default_remote_host
            local remote_port default_remote_port

            default_remote_host="$local_ip"
            default_remote_port="$local_port"

            remote_host="$(get_secret "${remoteHostKey}" "$default_remote_host")"
            remote_port="$(get_secret "${remotePortKey}" "$default_remote_port")"

            # Resolve SSH identity file at runtime
            local identity_line=""
            local configured_id="${configuredIdentity}"
            local user_id="$HOME/.ssh/$USER"

            if [ -n "$configured_id" ]; then
              eval configured_id="$configured_id"  # expand ~ and vars
            fi

            if [ -n "$configured_id" ] && [ -f "$configured_id" ]; then
              identity_line="  IdentityFile $configured_id"
            elif [ -f "$user_id" ]; then
              identity_line="  IdentityFile $user_id"
            else
              echo "Warning: No SSH identity file found for ${name}" >&2
              echo "  tried: ${configuredIdentity} and ~/.ssh/$USER" >&2
              echo "  SSH connections to ${name} may require a password" >&2
            fi

            # Append actual values to summary
            NODE_SUMMARIES="$NODE_SUMMARIES"'  '"${name} - ${node.role}/${node.nodeType}"$'\n'
            NODE_SUMMARIES="$NODE_SUMMARIES"'    local:  '"$local_ip:$local_port  (ssh ${name}-local)"$'\n'
            NODE_SUMMARIES="$NODE_SUMMARIES"'    remote: '"$remote_host:$remote_port  (ssh ${name}-remote)"$'\n'

            # Write SSH config
            {
              echo "# === ${name} ==="
              echo "Host ${name}-local"
              echo "  HostName $local_ip"
              echo "  Port $local_port"
              echo "  User ${sshUser}"
              [ -n "$identity_line" ] && echo "$identity_line"
              echo "  StrictHostKeyChecking accept-new"
              echo "  ConnectTimeout 10"
              echo ""
              echo "Host ${name}-remote"
              echo "  HostName $remote_host"
              echo "  Port $remote_port"
              echo "  User ${sshUser}"
              [ -n "$identity_line" ] && echo "$identity_line"
              echo "  StrictHostKeyChecking accept-new"
              echo "  ConnectTimeout 10"
              echo "  ServerAliveInterval 60"
              echo ""
            } >>"$SSH_CONFIG_FILE"
          }
        ''
      ) enabledNodes)}

      # Clean up decrypted secrets
      if [ -n "$SSH_SECRETS_FILE" ] && [ -f "$SSH_SECRETS_FILE" ]; then
        rm -f "$SSH_SECRETS_FILE"
      fi

      # --- SSH Keys Status Report ---
      KEYS_MISSING=""
      KEYS_LOADED=""

      ${pkgs.lib.concatStringsSep "\n" (pkgs.lib.mapAttrsToList (name: node:
        let
          configuredIdentity = node.identityFile or "";
        in ''
          # Resolve actual identity for ${name} (same logic as SSH config above)
          key_path=""
          configured_id="${configuredIdentity}"
          user_id="$HOME/.ssh/$USER"

          if [ -n "$configured_id" ]; then
            eval configured_id="$configured_id"
          fi

          if [ -n "$configured_id" ] && [ -f "$configured_id" ]; then
            key_path="$configured_id"
          elif [ -f "$user_id" ]; then
            key_path="$user_id"
          fi

          if [ -n "$key_path" ]; then
            fp="$(${pkgs.openssh}/bin/ssh-keygen -lf "$key_path" 2>/dev/null | awk '{print $2}')"
            if [ -n "$fp" ]; then
              if ${pkgs.openssh}/bin/ssh-add -l 2>/dev/null | awk '{print $2}' | grep -q "^$fp$"; then
                KEYS_LOADED="$KEYS_LOADED"'  '"$key_path  ($fp)"$'\n'
              else
                KEYS_MISSING="$KEYS_MISSING"'  ssh-add "'"$key_path"'"  # '"${name}"$'\n'
              fi
            fi
          fi
        ''
      ) enabledNodes)}

      if [ -n "$KEYS_MISSING" ] || [ -n "$KEYS_LOADED" ]; then
        echo ""
        echo "SSH Keys Status"
        if [ -n "$KEYS_MISSING" ]; then
          echo "  Missing (copy‑paste to load):"
          echo "  $KEYS_MISSING"
        fi
        if [ -n "$KEYS_LOADED" ]; then
          echo "  Loaded:"
          echo "  $KEYS_LOADED"
        fi
        echo "ssh config active: $SSH_CONFIG_FILE"
        echo ""
      fi

      echo "homelab-overkill"
      echo
      echo "nodes:"
      echo "$NODE_SUMMARIES"
      echo "commands:"
      echo "  deploy <install/update/test> <node>-local        - deploy via local connection"
      echo "  deploy <install/update/test> <node>-remote       - deploy via remote connection"
      echo "  secrets <cmd>                                    - manage secrets"
      echo "  ssh <node>-local                                 - ssh to node (local)"
      echo "  ssh <node>-remote                                - ssh to node (remote)"
      echo "  eval \$(nix run .#kubeconfig -- <node>-local)    - bootstrap kubeconfig (local)"
      echo "  eval \$(nix run .#kubeconfig -- <node>-remote)   - bootstrap kubeconfig (remote)"
      echo
      echo
    '';
  };
}
