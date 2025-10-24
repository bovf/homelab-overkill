{ nixpkgs, ... }:
{
  mkSecretsApp = system: {
    type = "app";
    program = toString (nixpkgs.legacyPackages.${system}.writeShellScript "secrets" ''
      set -euo pipefail

      # Layout: plaintext in bitwarden/, encrypted in secrets/
      BW_DIR="bitwarden"
      BW_SSH_DIR="$BW_DIR/ssh"
      ENC_DIR="secrets"
      SECRETS_PLAIN="$BW_DIR/secrets.yaml"
      SECRETS_ENC="$ENC_DIR/secrets.yaml"

      # Bitwarden config
      BITWARDEN_NOTE_NAME="homelab-secrets-plain"
      BW_SSH_FOLDER_ID="b29e40dd-d155-4bc8-beca-b3750069219a"

      # sops/age local identity derived from engineer SSH key
      export SOPS_AGE_KEY_FILE="$HOME/.config/sops/age/keys.txt"

      mkdir -p "$BW_DIR" "$BW_SSH_DIR" "$ENC_DIR" "$(dirname "$SOPS_AGE_KEY_FILE")"

      command="''${1:-help}"
      arg1="''${2:-}"

      ensuretool() { 
        if ! command -v "$1" >/dev/null 2>&1; then 
          echo "Error: missing tool '$1'"
          exit 1
        fi
      }

      unlockbw() {
        ensuretool bw
        ensuretool jq
        local st
        st="$(bw status --raw 2>/dev/null || true)"
        if [ -z "$st" ] || [ "$(echo "$st" | jq -r '.status')" = "unauthenticated" ]; then
          bw login >/dev/null
        fi
        export BW_SESSION="$(bw unlock --raw)"
      }

      get_engineer_priv() { 
        [ -f "$BW_SSH_DIR/engineer" ] && echo "$BW_SSH_DIR/engineer" || echo ""
      }
      
      get_engineer_pub() { 
        [ -f "$BW_SSH_DIR/engineer.pub" ] && echo "$BW_SSH_DIR/engineer.pub" || echo ""
      }

      setup_age_from_ssh() {
        # Derive age identity from engineer SSH private key
        local eng_priv
        eng_priv="$(get_engineer_priv)"
        echo "$eng_priv"
        if [ -z "$eng_priv" ]; then
          echo "Error: Missing engineer SSH key. Run 'pull' first."
          exit 1
        fi
        
        ensuretool ssh-to-age
        
        # Convert SSH private key to age identity
        if ! ssh-to-age -private-key -i "$eng_priv" > "$SOPS_AGE_KEY_FILE" 2>/dev/null; then
          echo "Error: Failed to convert SSH key to age identity"
          exit 1
        fi
        chmod 600 "$SOPS_AGE_KEY_FILE"
        echo "Created age identity from engineer SSH key at $SOPS_AGE_KEY_FILE"
        
        # Get public age key for display
        local pub
        pub="$(age-keygen -y "$SOPS_AGE_KEY_FILE" 2>/dev/null || true)"
        if [ -n "$pub" ]; then
          echo "Age public key: $pub"
        fi
      }

      add_recipient_if_missing() {
        local rec="$1"
        ensuretool yq
        
        if [ ! -f .sops.yaml ]; then
          cat > .sops.yaml <<EOF
creation_rules:
  - path_regex: $ENC_DIR/secrets\\.yaml
    key_groups:
      - age:
          - $rec
EOF
          echo "Created .sops.yaml with recipient $rec"
          return
        fi
        
        # Check if recipient exists
        if yq '.creation_rules[].key_groups[].age[] | select(. == "'"$rec"'")' .sops.yaml | grep -q "$rec"; then
          echo "Recipient $rec already present in .sops.yaml"
        else
          yq -i '
            (.creation_rules[] | select(.path_regex == "'"$ENC_DIR/secrets\\.yaml"'") | .key_groups[0].age) += ["'"$rec"'"]
          ' .sops.yaml
          echo "Added recipient $rec to .sops.yaml"
        fi
      }

      sync_ssh_to_yaml() {
        # Append SSH keys from bitwarden/ssh/ to secrets.yaml under ssh_keys section
        ensuretool yq
        
        if [ ! -f "$SECRETS_PLAIN" ]; then
          echo "Error: $SECRETS_PLAIN not found. Run 'pull' first."
          exit 1
        fi
        
        # Create a temporary file with ssh_keys section
        local tmp_ssh
        tmp_ssh="$(mktemp)"
        echo "ssh_keys:" > "$tmp_ssh"
        
        # Add all SSH keys from bitwarden/ssh/
        for keyfile in "$BW_SSH_DIR"/*; do
          [ -f "$keyfile" ] || continue
          local basename
          basename="$(basename "$keyfile")"
          local key_content
          key_content="$(cat "$keyfile")"
          
          # Properly escape and format for YAML
          echo "  $basename: |" >> "$tmp_ssh"
          echo "$key_content" | sed 's/^/    /' >> "$tmp_ssh"
        done
        
        # Merge with existing secrets.yaml, replacing ssh_keys section
        if yq -e '.ssh_keys' "$SECRETS_PLAIN" >/dev/null 2>&1; then
          # Remove existing ssh_keys section
          yq -i 'del(.ssh_keys)' "$SECRETS_PLAIN"
        fi
        
        # Append new ssh_keys section
        yq -i '. *= load("'"$tmp_ssh"'")' "$SECRETS_PLAIN"
        rm -f "$tmp_ssh"
        
        echo "Synced SSH keys into $SECRETS_PLAIN under ssh_keys section"
      }

      case "$command" in
        init)
          # Setup age identity from engineer SSH key
          eng_priv="$(get_engineer_priv)"
          if [ -z "$eng_priv" ]; then
            echo "Engineer SSH key not found. Run 'pull' first to download from Bitwarden."
            exit 1
          fi
          
          setup_age_from_ssh
          
          # Get public key for .sops.yaml
          pub="$(age-keygen -y "$SOPS_AGE_KEY_FILE")"
          
          if [ ! -f .sops.yaml ]; then
            cat > .sops.yaml <<EOF
creation_rules:
  - path_regex: $ENC_DIR/secrets\\.yaml
    key_groups:
      - age:
          - $pub
EOF
            echo "Initialized .sops.yaml with age recipient"
          else
            echo ".sops.yaml already exists"
          fi
          
          echo ""
          echo "Initialization complete."
          echo "Next: nix run .#secrets -- sync"
          ;;

        pull)
          unlockbw
          
          # Pull secrets note
          if ! bw get item "$BITWARDEN_NOTE_NAME" | jq -r '.notes' > "$SECRETS_PLAIN"; then
            echo "Error: could not pull Bitwarden note $BITWARDEN_NOTE_NAME"
            exit 1
          fi
          echo "Wrote $SECRETS_PLAIN"

          # Pull SSH keys from folder
          if [ -n "$BW_SSH_FOLDER_ID" ]; then
            items="$(bw list items --folderid "$BW_SSH_FOLDER_ID")"
          else
            items="$(bw list items)"
          fi

          echo "$items" | jq -c '.[] | select(.type==2) | {name,notes}' | while read -r row; do
            name="$(echo "$row" | jq -r '.name')"
            notes="$(echo "$row" | jq -r '.notes')"
            case "$name" in
              *.pub)
                echo "$notes" > "$BW_SSH_DIR/$name"
                chmod 644 "$BW_SSH_DIR/$name"
                ;;
              *)
                echo "$notes" > "$BW_SSH_DIR/$name"
                chmod 600 "$BW_SSH_DIR/$name"
                ;;
            esac
          done
          echo "Synced SSH keys to $BW_SSH_DIR"
          
          # Auto-sync SSH keys into secrets.yaml
          sync_ssh_to_yaml
          ;;

        push)
          unlockbw
          ensuretool jq
          
          if [ ! -f "$SECRETS_PLAIN" ]; then
            echo "Missing $SECRETS_PLAIN; run pull or decrypt first"
            exit 1
          fi
          
          # Remove ssh_keys section before pushing (keys stay in bitwarden/ssh/)
          tmp="$(mktemp)"
          yq 'del(.ssh_keys)' "$SECRETS_PLAIN" > "$tmp"
          
          item="$(bw get item "$BITWARDEN_NOTE_NAME")"
          tmp_item="$(mktemp)"
          notes="$(cat "$tmp")"
          echo "$item" \
            | jq --arg notes "$notes" '.notes=$notes' \
            | bw encode \
            > "$tmp_item"
          bw edit item "$BITWARDEN_NOTE_NAME" "$tmp_item" >/dev/null
          
          rm -f "$tmp" "$tmp_item"
          echo "Updated Bitwarden note $BITWARDEN_NOTE_NAME (SSH keys remain separate)"
          ;;

        sync)
          ensuretool sops
          
          if [ ! -f "$SECRETS_PLAIN" ]; then
            echo "Missing $SECRETS_PLAIN; run pull first"
            exit 1
          fi
          
          # Ensure SSH keys are in secrets.yaml
          sync_ssh_to_yaml
          
          cp "$SECRETS_PLAIN" "$SECRETS_ENC"
          sops --encrypt --in-place "$SECRETS_ENC"
          echo "Encrypted $SECRETS_ENC from $SECRETS_PLAIN"
          ;;

        encrypt)
          ensuretool sops
          
          if [ -f "$SECRETS_PLAIN" ]; then
            # Ensure SSH keys are synced before encrypting
            sync_ssh_to_yaml
            cp "$SECRETS_PLAIN" "$SECRETS_ENC"
          fi
          
          sops --encrypt --in-place "$SECRETS_ENC"
          echo "Encrypted $SECRETS_ENC"
          ;;

        decrypt)
          ensuretool sops
          sops --decrypt "$SECRETS_ENC" > "$SECRETS_PLAIN"
          echo "Decrypted to $SECRETS_PLAIN (do not commit plaintext)"
          ;;

        edit)
          ensuretool sops
          sops "$SECRETS_ENC"
          echo "Edited $SECRETS_ENC"
          ;;

        rekey)
          ensuretool sops
          sops updatekeys "$SECRETS_ENC"
          echo "Rekeyed $SECRETS_ENC per .sops.yaml recipients"
          ;;

        bootstrap)
          ensuretool ssh-to-age
          host="''${arg1:-}"
          
          if [ -z "$host" ]; then
            echo "Usage: secrets bootstrap <hostname>"
            exit 1
          fi

          # Ensure engineer keys exist
          eng_priv="$(get_engineer_priv)"
          eng_pub="$(get_engineer_pub)"
          
          if [ -z "$eng_priv" ] || [ -z "$eng_pub" ]; then
            echo "Missing engineer SSH keys. Run: nix run .#secrets -- pull"
            exit 1
          fi

          # Derive Age recipient from engineer.pub
          AGE_RECIPIENT="$(ssh-to-age < "$eng_pub")"
          add_recipient_if_missing "$AGE_RECIPIENT"

          # Ensure encrypted secrets exist
          if [ ! -f "$SECRETS_ENC" ]; then
            if [ -f "$SECRETS_PLAIN" ]; then
              sync_ssh_to_yaml
              cp "$SECRETS_PLAIN" "$SECRETS_ENC"
              ensuretool sops
              sops --encrypt --in-place "$SECRETS_ENC"
            else
              echo "Missing secrets. Run 'pull' first."
              exit 1
            fi
          fi

          # Rekey for new recipient
          ensuretool sops
          sops updatekeys "$SECRETS_ENC"

          # Stage --extra-files for nixos-anywhere
          OUT_DIR=".cache/extra-files/$host"
          mkdir -p "$OUT_DIR/root/.ssh"
          
          cp "$eng_priv" "$OUT_DIR/root/.ssh/id_ed25519"
          cp "$eng_pub" "$OUT_DIR/root/.ssh/id_ed25519.pub"
          cp "$eng_pub" "$OUT_DIR/root/.ssh/authorized_keys"
          
          chmod 700 "$OUT_DIR/root/.ssh"
          chmod 600 "$OUT_DIR/root/.ssh/id_ed25519"
          chmod 644 "$OUT_DIR/root/.ssh/id_ed25519.pub"
          chmod 600 "$OUT_DIR/root/.ssh/authorized_keys"

          echo ""
          echo "Bootstrap complete for $host"
          echo "Staged at: $OUT_DIR"
          echo ""
          echo "Deploy with:"
          echo "  nix run .#deploy -- install $host"
          echo ""
          echo "The target will use /root/.ssh/id_ed25519 for sops-nix decryption."
          ;;

        help|*)
          cat <<EOF
Usage: nix run .#secrets -- <command> [args]

Commands:
  init        Setup age identity from engineer SSH key (requires pull first).
  pull        Pull secrets + SSH keys from Bitwarden, auto-sync to secrets.yaml.
  push        Push secrets back to Bitwarden (excludes SSH keys section).
  sync        Sync SSH keys to secrets.yaml and encrypt to $SECRETS_ENC.
  encrypt     Encrypt $SECRETS_ENC (syncs SSH keys first if plaintext exists).
  decrypt     Decrypt $SECRETS_ENC to plaintext.
  edit        Edit $SECRETS_ENC with sops.
  rekey       Re-encrypt for all recipients in .sops.yaml.
  bootstrap   Prepare a new host for nixos-anywhere install with secrets.

Workflow:
  1. nix run .#secrets -- pull          # Download from Bitwarden
  2. nix run .#secrets -- init          # Setup age key from engineer SSH
  3. Edit bitwarden/secrets.yaml        # Make changes
  4. nix run .#secrets -- sync          # Encrypt with SSH keys included
  5. nix run .#secrets -- bootstrap engineer  # Prepare for deploy
  6. nix run .#deploy -- install engineer     # Install with secrets

Notes:
- SSH keys are stored in bitwarden/ssh/ and merged into secrets.yaml
- Target must use: sops.age.sshKeyPaths = [ "/root/.ssh/id_ed25519" ]
- Keep bitwarden/ in .gitignore
EOF
          ;;
      esac
    '');
  };
}
