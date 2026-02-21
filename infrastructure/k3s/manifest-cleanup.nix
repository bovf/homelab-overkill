{ config, lib, pkgs, ... }:
with lib;
let
  cfg = config.services.k3s.manifestCleanup;

  manifestDir = "/var/lib/rancher/k3s/server/manifests";

  expectedManifestFiles =
    mapAttrsToList (_: m: m.target) config.services.k3s.manifests ++
    mapAttrsToList (_: t: baseNameOf t.path) config.sops.templates;

  expectedFilesJson = pkgs.writeText "expected-manifests.json" (builtins.toJSON expectedManifestFiles);

  cleanupScript = pkgs.writeShellScript "k3s-manifest-cleanup" ''
    set -euo pipefail

    cd "${manifestDir}"

    # Skip if directory doesn't exist yet
    [[ -d . ]] || exit 0

    # Read expected files
    EXPECTED_FILES=$(${pkgs.jq}/bin/jq -r '.[]' ${expectedFilesJson})

    # Find and remove orphaned symlinks
    for file in *; do
      # Skip non-symlinks (k3s built-in files like traefik.yaml, ccm.yaml, etc.)
      [[ -L "$file" ]] || continue

      # Check if this file is in our expected list
      if ! echo "$EXPECTED_FILES" | grep -qx "$file"; then
        echo "Removing orphaned manifest symlink: $file"
        rm -f "$file"
      fi

      # Also remove broken symlinks (target no longer exists)
      if [[ ! -e "$file" ]]; then
        echo "Removing broken symlink: $file"
        rm -f "$file"
      fi
    done
  '';

in
{
  options.services.k3s.manifestCleanup = {
    enable = mkEnableOption "Automatic cleanup of orphaned k3s manifest symlinks";
  };

  config = mkIf cfg.enable {
    systemd.services.k3s-manifest-cleanup = {
      description = "Clean up orphaned k3s manifest symlinks";
      wantedBy = [ "multi-user.target" ];
      before = [ "k3s.service" ];
      after = [ "sops-nix.service" ];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = cleanupScript;
        RemainAfterExit = true;
      };
    };
  };
}
