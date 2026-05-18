# On-host blueprint rendering + sync to pangolin's REST API.
{ config, lib, pkgs, ... }:
with lib;
let
  cfg = config.services.pangolin-kwg;
  bp  = cfg.blueprintSync;

  # Inject this Basic-WG site into the instances map so the shared lib's
  # siteIdKey lookup resolves for kwg-routed resources.
  instances = config.workloads.pangolinInstances // {
    "${cfg.instance}" = {
      siteIdKey = cfg.site.siteIdSopsPath;
    };
  };

  # The blueprint endpoint replaces the entire org blueprint, so all
  # resources must be sent (not just the kwg subset).
  resources = config.workloads.pangolinResources;

  # Pangolin can't resolve cluster DNS, so kwg-routed resources point at
  # our tunnel-side IP; kube-proxy's externalIPs rule on each backend
  # Service handles the actual delivery.
  tunnelHost =
    lib.elemAt (lib.splitString "/" (lib.elemAt cfg.site.address 0)) 0;

  resourcesList =
    mapAttrsToList (k: v: v // {
      _key = k;
      targetHostname =
        if v.viaKernelWg then tunnelHost else v.targetHostname;
    }) resources;

  blueprint = import ../../workloads/lib/pangolin-blueprint.nix {
    inherit config lib instances;
  };

  blueprintYaml = ''
    public-resources:
${blueprint.resourcesYaml resourcesList}
  '';

  blueprintPath = "/etc/pangolin-kwg/blueprint.yaml";

  syncScript = pkgs.writeShellScript "pangolin-kwg-blueprint-sync" ''
    set -euo pipefail

    API_KEY=$(cat "${config.sops.secrets.${bp.apiKeySopsPath}.path}")

    # API expects base64-encoded JSON (newt's --blueprint-file takes YAML).
    PAYLOAD=$(${pkgs.yq-go}/bin/yq -o=json '.' "${blueprintPath}" \
              | ${pkgs.jq}/bin/jq -Rs '{blueprint: @base64}')

    ${pkgs.curl}/bin/curl -fsS --retry 3 --retry-delay 5 \
      -X PUT "${bp.endpoint}/v1/org/${bp.orgId}/blueprint" \
      -H "Authorization: Bearer $API_KEY" \
      -H "Content-Type: application/json" \
      -d "$PAYLOAD"
    echo
  '';

in {
  config = mkIf (cfg.enable && bp.enable) {
    assertions = [
      {
        assertion = bp.orgId != null;
        message   = "services.pangolin-kwg.blueprintSync.orgId must be set when blueprintSync.enable = true";
      }
      {
        assertion = bp.endpoint != null;
        message   = "services.pangolin-kwg.blueprintSync.endpoint must be set when blueprintSync.enable = true";
      }
    ];

    sops.templates."pangolin-kwg/blueprint.yaml" = {
      content = blueprintYaml;
      path    = blueprintPath;
      owner   = "root";
      group   = "root";
      mode    = "0600";
    };

    # Re-fire on every rebuild to recover from pangolin/gerbil state drift
    # (e.g. gerbil restart wiped peers) even when the local YAML didn't
    # change. Can't use restartTriggers=[toplevel] — that's a cycle.
    system.activationScripts.pangolin-kwg-blueprint-resync = lib.stringAfter [ "etc" ] ''
      ${pkgs.systemd}/bin/systemctl restart pangolin-kwg-blueprint-sync.service || true
    '';

    systemd.services.pangolin-kwg-blueprint-sync = {
      description = "Sync pangolin blueprint to the REST API";
      wantedBy    = [ "multi-user.target" ];
      after = [
        "sops-nix.service"
        "network-online.target"
        "wg-quick-${cfg.interfaceName}.service"
      ];
      wants = [ "network-online.target" ];
      serviceConfig = {
        Type            = "oneshot";
        RemainAfterExit = true;
        ExecStart       = syncScript;
      };
      restartTriggers = [ blueprintYaml ];
    };
  };
}
