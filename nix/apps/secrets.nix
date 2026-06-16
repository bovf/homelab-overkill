{nixpkgs, ...}: {
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
            # The new layout: one folder, one secure note per top-level yaml key.
            # `pull` concatenates all notes in this folder (alphabetical) into
            # bitwarden/secrets.yaml, then appends ssh_keys: synthesized from
            # the SSH folder below. `push` splits the local file the other way.
            BW_SECRETS_FOLDER_NAME="homelab-secrets"
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

            bw_status() {
              # Re-evaluate against a clean BW_SESSION so a stale value exported in
              # the parent shell can't make `bw status` lie about being unlocked.
              env -u BW_SESSION bw status 2>/dev/null | jq -r '.status' 2>/dev/null || echo unauthenticated
            }

            unlockbw() {
              ensuretool bw
              ensuretool jq

              local status
              status="$(bw_status)"

              if [ "$status" = "unauthenticated" ]; then
                echo "Logging into Bitwarden..." >&2
                # Do NOT redirect stdout: bw uses inquirer prompts (email, master
                # password, 2FA) on stdout. Suppressing them makes login appear to
                # hang and silently fail.
                if ! env -u BW_SESSION bw login; then
                  echo "Error: bw login failed" >&2
                  exit 1
                fi
                status="$(bw_status)"
              fi

              if [ "$status" = "unauthenticated" ]; then
                echo "Error: bw still reports unauthenticated after login" >&2
                exit 1
              fi

              echo "Unlocking Bitwarden vault..." >&2
              local session
              session="$(env -u BW_SESSION bw unlock --raw)" || {
                echo "Error: bw unlock failed" >&2
                exit 1
              }
              if [ -z "$session" ]; then
                echo "Error: bw unlock returned an empty session" >&2
                exit 1
              fi
              export BW_SESSION="$session"
            }

            # Resolve the homelab-secrets folder name to its Bitwarden folder ID.
            # Cached on first call; subsequent calls are free.
            get_secrets_folder_id() {
              if [ -n "''${SECRETS_FOLDER_ID:-}" ]; then
                echo "$SECRETS_FOLDER_ID"
                return
              fi
              ensuretool bw
              ensuretool jq
              local id
              id=$(bw list folders | jq -r --arg n "$BW_SECRETS_FOLDER_NAME" \
                    '.[] | select(.name==$n) | .id')
              if [ -z "$id" ] || [ "$id" = "null" ]; then
                echo "Error: BW folder '$BW_SECRETS_FOLDER_NAME' not found." >&2
                echo "       Create it in Bitwarden first, then re-run." >&2
                exit 1
              fi
              SECRETS_FOLDER_ID="$id"
              echo "$id"
            }

            get_ssh_priv() {
              local key_name="$1"
              [ -f "$BW_SSH_DIR/$key_name" ] && echo "$BW_SSH_DIR/$key_name" || echo ""
            }

            get_ssh_pub() {
              local key_name="$1"
              [ -f "$BW_SSH_DIR/$key_name.pub" ] && echo "$BW_SSH_DIR/$key_name.pub" || echo ""
            }

            get_engineer_priv() {
              get_ssh_priv "engineer"
            }

            get_engineer_pub() {
              get_ssh_pub "engineer"
            }

            host_ssh_key_name() {
              local host="$1"
              case "$host" in
                engineer) echo "engineer" ;;
                pangolin) echo "theadministrator" ;;
                *) echo "$host" ;;
              esac
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
                SOPS_RECIPIENT="$rec" ENC_DIR="$ENC_DIR" yq -n '
                  .creation_rules = [{
                    "path_regex": strenv(ENC_DIR) + "/secrets\\.yaml",
                    "key_groups": [{"age": [strenv(SOPS_RECIPIENT)]}]
                  }]
                ' > .sops.yaml
                echo "Created .sops.yaml with recipient $rec"
                return
              fi

              # Check the main secrets.yaml rule only. Raw SSH public-key recipients
              # contain spaces, so pass them through the environment instead of
              # interpolating into the yq expression.
              if SOPS_RECIPIENT="$rec" ENC_DIR="$ENC_DIR" yq -r '
                .creation_rules[]
                | select(.path_regex == strenv(ENC_DIR) + "/secrets\\.yaml" or .path_regex == strenv(ENC_DIR) + "/secrets\\.yaml$")
                | .key_groups[].age[]
                | select(. == strenv(SOPS_RECIPIENT))
              ' .sops.yaml | grep -Fxq "$rec"; then
                echo "Recipient already present in .sops.yaml: $rec"
              else
                SOPS_RECIPIENT="$rec" ENC_DIR="$ENC_DIR" yq -i '
                  (.creation_rules[]
                    | select(.path_regex == strenv(ENC_DIR) + "/secrets\\.yaml" or .path_regex == strenv(ENC_DIR) + "/secrets\\.yaml$")
                    | .key_groups[0].age) += [strenv(SOPS_RECIPIENT)]
                ' .sops.yaml
                echo "Added recipient to .sops.yaml: $rec"
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
                ensuretool jq

                # Concatenate every note in the homelab-secrets folder (alphabetical
                # by name) into bitwarden/secrets.yaml. Each note is a self-contained
                # mini-yaml rooted at its top-level key (e.g. note `admin` body
                # starts with `admin:`), so plain concatenation produces one valid
                # multi-key yaml.
                folder_id=$(get_secrets_folder_id)
                items=$(bw list items --folderid "$folder_id")
                note_count=$(echo "$items" | jq '[.[] | select(.type==2)] | length')
                if [ "$note_count" -eq 0 ]; then
                  echo "Error: BW folder '$BW_SECRETS_FOLDER_NAME' is empty." >&2
                  echo "       Populate it (see scripts/migrate-bw-secrets-split.sh)." >&2
                  exit 1
                fi

                # Build the whole concatenated file in one jq pass — shells can't
                # read multi-line "notes" payloads with a single-line read loop.
                # Each note becomes "# --- <name> ---\n<body>\n\n".
                echo "$items" \
                  | jq -r '
                      sort_by(.name | ascii_downcase)
                      | map(select(.type == 2))
                      | map("# --- " + .name + " ---\n" + (.notes // "") + "\n\n")
                      | join("")
                    ' > "$SECRETS_PLAIN"

                # Progress: list the notes that landed in the file.
                echo "$items" \
                  | jq -r 'sort_by(.name | ascii_downcase) | .[] | select(.type==2) | "  + " + .name'
                echo "Wrote $SECRETS_PLAIN ($note_count notes concatenated)"

                # Pull SSH keys from the dedicated SSH folder (unchanged).
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

                # Auto-append ssh_keys: section into the assembled file.
                sync_ssh_to_yaml
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
                host="''${arg1:-}"

                if [ -z "$host" ]; then
                  echo "Usage: secrets bootstrap <hostname>"
                  exit 1
                fi

                host_key_name="$(host_ssh_key_name "$host")"
                host_priv="$(get_ssh_priv "$host_key_name")"
                host_pub="$(get_ssh_pub "$host_key_name")"

                if [ -z "$host_priv" ] || [ -z "$host_pub" ]; then
                  echo "Missing SSH key pair '$host_key_name' for host '$host'. Run: nix run .#secrets -- pull"
                  exit 1
                fi

                # Add the raw SSH public key as a SOPS age recipient. SOPS supports
                # raw SSH recipients directly, including ssh-rsa. Also add a converted
                # age recipient when ssh-to-age supports the key type, preserving
                # compatibility with sops-nix age.sshKeyPaths during migration.
                RAW_SSH_RECIPIENT="$(cat "$host_pub")"
                add_recipient_if_missing "$RAW_SSH_RECIPIENT"

                if command -v ssh-to-age >/dev/null 2>&1; then
                  CONVERTED_RECIPIENT="$(ssh-to-age < "$host_pub" 2>/dev/null || true)"
                  if [ -n "$CONVERTED_RECIPIENT" ]; then
                    add_recipient_if_missing "$CONVERTED_RECIPIENT"
                  else
                    echo "ssh-to-age could not convert '$host_key_name.pub'; raw SSH recipient was added instead."
                  fi
                else
                  echo "ssh-to-age not found; raw SSH recipient was added without converted age compatibility."
                fi

                # Ensure encrypted secrets exist. Do not rekey automatically: rekeying
                # is an explicit operator action during the SOPS recipient migration.
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

                if [ "''${HOMELAB_SECRETS_BOOTSTRAP_REKEY:-0}" = "1" ]; then
                  ensuretool sops
                  sops updatekeys "$SECRETS_ENC"
                  echo "Rekeyed $SECRETS_ENC per .sops.yaml recipients"
                else
                  echo "Skipped sops updatekeys; run explicitly after approving recipient changes:"
                  echo "  sops updatekeys $SECRETS_ENC"
                  echo "or set HOMELAB_SECRETS_BOOTSTRAP_REKEY=1 for bootstrap-time rekey."
                fi

                # Stage --extra-files for nixos-anywhere. The host-named key is the
                # preferred SOPS identity; id_ed25519 is kept during migration for
                # existing modules and tools that still expect the default SSH name.
                OUT_DIR=".cache/extra-files/$host"
                mkdir -p "$OUT_DIR/root/.ssh"

                cp "$host_priv" "$OUT_DIR/root/.ssh/$host_key_name"
                cp "$host_pub" "$OUT_DIR/root/.ssh/$host_key_name.pub"
                cp "$host_priv" "$OUT_DIR/root/.ssh/id_ed25519"
                cp "$host_pub" "$OUT_DIR/root/.ssh/id_ed25519.pub"
                cp "$host_pub" "$OUT_DIR/root/.ssh/authorized_keys"

                chmod 700 "$OUT_DIR/root/.ssh"
                chmod 600 "$OUT_DIR/root/.ssh/$host_key_name"
                chmod 644 "$OUT_DIR/root/.ssh/$host_key_name.pub"
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
                echo "The target will prefer /root/.ssh/$host_key_name for sops-nix decryption."
                echo "Compatibility fallback also staged at /root/.ssh/id_ed25519."
                ;;

              help|*)
                cat <<EOF
      Usage: nix run .#secrets -- <command> [args]

      Commands:
        init        Setup age identity from engineer SSH key (requires pull first).
        pull        Pull all notes in BW folder '$BW_SECRETS_FOLDER_NAME' + SSH
                    keys, assemble bitwarden/secrets.yaml.
        sync        Sync SSH keys to secrets.yaml and encrypt to $SECRETS_ENC.
        encrypt     Encrypt $SECRETS_ENC (syncs SSH keys first if plaintext exists).
        decrypt     Decrypt $SECRETS_ENC to plaintext.
        edit        Edit $SECRETS_ENC with sops.
        rekey       Re-encrypt for all recipients in .sops.yaml.
        bootstrap   Prepare a new host for nixos-anywhere install with secrets.
                    Adds raw SSH recipients; set HOMELAB_SECRETS_BOOTSTRAP_REKEY=1
                    to also run sops updatekeys during bootstrap.

      Workflow (edits live in Bitwarden UI):
        1. Edit the relevant note(s) in the BW '$BW_SECRETS_FOLDER_NAME' folder.
        2. nix run .#secrets -- pull           # Re-assemble bitwarden/secrets.yaml
        3. nix run .#secrets -- sync           # Encrypt to $SECRETS_ENC for git
        4. nix run .#secrets -- bootstrap engineer  # (only when adding a new host)
        5. nix run .#secrets -- rekey      # explicit approval point after recipient changes
        6. nix run .#deploy -- update engineer-local

      Bitwarden layout:
      - Folder '$BW_SECRETS_FOLDER_NAME': one secure note per top-level yaml key.
        Each note body is a self-contained mini-yaml rooted at its key.
        EDIT NOTES DIRECTLY IN BITWARDEN — this script only reads, never writes.
      - Separate SSH folder: one note per SSH key (engineer, engineer.pub, ...).
      - The 'sops' section is encryption metadata and never lands in BW.
      - The 'ssh_keys' section is synthesized from the SSH folder on pull.

      Notes:
      - Local plaintext lives in bitwarden/ (gitignored).
      - Target should prefer its named host key in sops.age.sshKeyPaths and
        SOPS_AGE_SSH_PRIVATE_KEY_FILE, with /root/.ssh/id_ed25519 kept only
        as migration fallback.
      EOF
                ;;
            esac
    '');
  };
}
