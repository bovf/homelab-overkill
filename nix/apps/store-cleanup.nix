{nixpkgs, ...}: {
  mkStoreCleanupApp = system: enabledNodes: let
    inherit (nixpkgs) lib;
    pkgs = nixpkgs.legacyPackages.${system};
    targets = lib.concatMapAttrs (name: node:
      lib.optionalAttrs (node.localTarget or true) {"${name}-local" = node.hostname;}
      // lib.optionalAttrs (node.remoteTarget or true) {"${name}-remote" = node.hostname;})
    enabledNodes;
    targetCases = lib.concatStringsSep "\n" (lib.mapAttrsToList (target: hostname: ''
        ${target}) expected_host=${lib.escapeShellArg hostname} ;;
      '')
      targets);

    # Sent as a quoted command, not stdin: sudo can use the caller's terminal.
    # Use the node's tools, so a Darwin client can maintain a Linux node too.
    remoteScript = ''
      set -euo pipefail
      export LC_ALL=C
      action="$1"
      expected_host="$2"
      expected_system="''${3:-}"
      expected_boot="''${4:-}"
      profile=/nix/var/nix/profiles/system

      die() { echo "Error: $*" >&2; exit 1; }
      [ "$(uname -n)" = "$expected_host" ] || die "SSH reached the wrong node."
      current=$(readlink -e /run/current-system)
      booted=$(readlink -e /run/booted-system)
      selected=$(readlink -e "$profile")
      boot_id=$(cat /proc/sys/kernel/random/boot_id)

      check_selected() {
        [ "$current" = "$selected" ] || die "Active and selected systems differ; finish deployment first."
        [ "$current" = "$expected_system" ] || die "System changed during maintenance; start again."
        [ "$boot_id" = "$expected_boot" ] || die "Boot changed during maintenance; start again."
      }

      check_health() {
        check_selected
        [ "$booted" = "$current" ] || die "Reboot required; use --clean --reboot."
        systemctl is-system-running --quiet || die "System is not healthy/running; inspect failed units."
        systemctl is-active --quiet sshd || die "sshd is not active."
        case "$expected_host" in
          engineer) systemctl is-active --quiet k3s || die "k3s is not active." ;;
          pangolin)
            for service in pangolin gerbil traefik; do
              systemctl is-active --quiet "$service" || die "$service is not active."
            done
            ;;
        esac
      }

      preview() {
        check_selected
        generations=$(nix-env -p "$profile" --list-generations)
        printf '%s\n' "$generations"
        active_generation=$(awk '$NF == "(current)" {print $1}' <<< "$generations")
        latest_generation=$(awk 'NF {last=$1} END {print last}' <<< "$generations")
        [[ "$active_generation" =~ ^[0-9]+$ && "$active_generation" = "$latest_generation" ]] \
          || die "Profile was rolled back or generation list is invalid; resolve newer generations before pruning."
        echo "Keep current and one previous system generation; prune:"
        nix-env -p "$profile" --delete-generations --dry-run +2
      }

      human() { numfmt --to=iec-i --suffix=B -- "$1"; }
      store_bytes() { du -sx -B1 -- /nix/store | cut -f1; }
      usage_report() {
        local total used available
        read -r total used available < <(df -B1 --output=size,used,avail -- / | tail -n1)
        printf 'Root filesystem: total %s; used %s; available %s\n' \
          "$(human "$total")" "$(human "$used")" "$(human "$available")"
        read -r total used store_available < <(df -B1 --output=size,used,avail -- /nix/store | tail -n1)
        if [ "$(stat -c %d /)" != "$(stat -c %d /nix/store)" ]; then
          printf 'Store filesystem: total %s; used %s; available %s\n' \
            "$(human "$total")" "$(human "$used")" "$(human "$store_available")"
        fi
        store_size=$(store_bytes)
        printf 'Nix store: %s (%s bytes), %s%% of its filesystem capacity\n' \
          "$(human "$store_size")" "$store_size" "$(awk -v size="$store_size" -v total="$total" 'BEGIN {printf "%.2f", 100*size/total}')"
      }

      case "$action" in
        state)
          printf '%s %s %s %s %s\n' "$(id -u)" "$boot_id" "$current" "$booted" "$selected"
          ;;
        report)
          usage_report
          printf 'Active:   %s\nBooted:   %s\nSelected: %s\n' "$current" "$booted" "$selected"
          if [ "$booted" = "$current" ] && [ "$current" = "$selected" ]; then
            echo 'Reboot required: no'
          else
            echo 'Reboot required: yes (or deployment is incomplete)'
          fi
          nix-env -p "$profile" --list-generations
          ;;
        preview) preview ;;
        health) check_health ;;
        reboot)
          check_selected
          [ "$(id -u)" = 0 ] || die "Reboot requires root."
          systemctl reboot
          ;;
        clean)
          [ "$(id -u)" = 0 ] || die "Cleanup requires root."
          check_health
          preview
          echo '=== Before cleanup ==='
          usage_report
          before_size=$store_size
          before_available=$store_available
          nix-env -p "$profile" --delete-generations +2
          # Update boot entries before GC; if this fails, do not collect paths.
          "$current/bin/switch-to-configuration" boot
          [ "$(readlink -e "$profile")" = "$current" ] || die "Profile changed; skipping GC."
          nix-store --gc
          after_gc=$(store_bytes)
          nix-store --optimise
          echo '=== After cleanup ==='
          usage_report
          printf 'GC store reduction: %s\nOptimisation store reduction: %s\nTotal store reduction: %s\nObserved filesystem space recovered: %s\n' \
            "$(human "$((before_size - after_gc))")" \
            "$(human "$((after_gc - store_size))")" \
            "$(human "$((before_size - store_size))")" \
            "$(human "$((store_available - before_available))")"
          echo 'Allocated-byte measurements; other builds/workloads can affect the observed deltas.'
          ;;
        *) die "Unknown remote action." ;;
      esac
    '';
  in {
    type = "app";
    program = toString (pkgs.writeShellScript "store-cleanup" ''
      set -euo pipefail
      die() { echo "Error: $*" >&2; exit 1; }
      help() {
        cat <<'EOF'
      Usage: nix run .#store-cleanup -- NODE_TARGET --report
             nix run .#store-cleanup -- NODE_TARGET --clean [--reboot]

      Targets: ${lib.concatStringsSep ", " (lib.attrNames targets)}
      --report   Read-only disk/store usage, generations and reboot status.
      --clean    Confirm, keep current + one previous system generation, GC and optimise.
      --reboot   With --clean only: reboot, wait for healthy return, then clean.

      Run inside nix develop (SSH_CONFIG_FILE required). No concurrent deployments.
      User profiles, other GC roots, application data and backups are untouched.
      Reboot via engineer-local: engineer-remote's SSH resource is disabled on startup.
      Existing automatic GC policy is unchanged by this command.
      EOF
      }

      if [ "$#" = 0 ]; then help; exit 0; fi
      target=""
      mode=""
      reboot=0
      for arg in "$@"; do
        case "$arg" in
          --help|-h) help; exit 0 ;;
          --report|--clean)
            [ -z "$mode" ] || die 'Choose exactly one of --report or --clean.'
            mode="''${arg#--}"
            ;;
          --reboot)
            [ "$reboot" = 0 ] || die 'Repeated --reboot.'
            reboot=1
            ;;
          -*) die "Unknown option: $arg" ;;
          *) [ -z "$target" ] || die 'Specify exactly one node target.'; target="$arg" ;;
        esac
      done
      case "$target" in
        ${targetCases}
        *) die 'Invalid or missing node target; use --help.' ;;
      esac
      [ -n "$mode" ] || die 'Specify --report or --clean.'
      if [ "$reboot" = 1 ]; then
        [ "$mode" = clean ] || die '--reboot requires --clean.'
        [ "$target" != engineer-remote ] || die 'Use engineer-local to reboot; public SSH is disabled on startup.'
      fi
      [ -n "''${SSH_CONFIG_FILE:-}" ] && [ -f "$SSH_CONFIG_FILE" ] || die 'Enter nix develop first (SSH_CONFIG_FILE missing).'
      command -v ssh >/dev/null || die 'ssh is unavailable.'
      ssh_args=(-F "$SSH_CONFIG_FILE" -o BatchMode=yes -o ConnectTimeout=5 -o ServerAliveInterval=5 -o ServerAliveCountMax=1)
      # Expanded on the node, not on this client.
      # shellcheck disable=SC2016
      remote_script=${lib.escapeShellArg remoteScript}
      remote_uid=0
      expected_system=""
      expected_boot=""

      remote() {
        local action="$1" command prefix=""
        local tty=()
        printf -v command 'bash -c %q -- %q %q %q %q' \
          "$remote_script" "$action" "$expected_host" "$expected_system" "$expected_boot"
        # Even nix-env's dry-run preview locks the root-owned system profile.
        if [[ "$action" = preview || "$action" = clean || "$action" = reboot ]] && [ "$remote_uid" != 0 ]; then
          prefix='sudo -- '
          tty=(-t)
        fi
        # Each remote argument was quoted with Bash %q above.
        # shellcheck disable=SC2029
        ssh "''${ssh_args[@]}" "''${tty[@]}" "$target" "$prefix$command"
      }

      if [ "$mode" = report ]; then remote report; exit 0; fi
      state=$(remote state)
      read -r remote_uid expected_boot expected_system booted selected <<< "$state"
      [[ "$remote_uid" =~ ^[0-9]+$ && -n "$expected_boot" && -n "$expected_system" && -n "$selected" ]] || die 'Invalid node state.'
      [ "$expected_system" = "$selected" ] || die 'Active and selected systems differ; finish deployment first.'
      if [ "$reboot" = 0 ]; then remote health; fi
      remote preview
      echo "Target: $target. Keep current + one previous system generation; garbage-collect and optimise."
      if [ "$reboot" = 1 ]; then echo 'This will REBOOT the node and interrupt its services.'; fi
      printf 'Type %s to confirm: ' "$target"
      read -r confirmation || die 'Confirmation required; aborting.'
      [ "$confirmation" = "$target" ] || die 'Cancelled.'

      if [ "$reboot" = 1 ]; then
        old_boot=$expected_boot
        # SSH may disconnect before systemctl returns; a changed boot ID is proof.
        status=0
        remote reboot || status=$?
        [[ "$status" = 0 || "$status" = 255 ]] || die 'Reboot request failed; no cleanup performed.'
        ready=0
        for ((attempt=0; attempt<60; attempt++)); do
          sleep 5
          if state=$(remote state 2>/dev/null); then
            read -r remote_uid new_boot current booted selected <<< "$state"
            [ "$new_boot" != "$old_boot" ] || continue
            [[ -n "$new_boot" && "$current" = "$expected_system" && "$booted" = "$expected_system" && "$selected" = "$expected_system" ]] \
              || die 'Unexpected system after reboot; no cleanup performed.'
            expected_boot=$new_boot
            if remote health >/dev/null 2>&1; then ready=1; break; fi
          fi
          printf '.'
        done
        echo
        [ "$ready" = 1 ] || die 'Reboot/health check timed out after 60 attempts; no cleanup performed.'
      fi
      remote clean
    '');
  };
}
