{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.services.pangolin-kwg;
  bp = cfg.blueprintSync;
  tunnelHost = lib.head (lib.splitString "/" (lib.head cfg.site.address));
in {
  workloads.pangolinResources.cache = {
    name = "Attic Nix Cache";
    protocol = "http";
    domainKey = "pangolin/resources/cache/domain";
    enabled = true;
    ssoEnabled = false;
    targetHostname = "attic-cache.proxy.svc.cluster.local";
    targetMethod = "http";
    targetPort = 8102;
    newtInstance = "engineer-kernel";
    viaKernelWg = true;
    lanIP = "192.168.2.23";
    # Basic WireGuard has no Newt agent to report target health.
    healthcheck = null;
  };

  sops.secrets."pangolin/resources/cache/domain" = {};

  systemd.services.pangolin-kwg-blueprint-sync = lib.mkIf (cfg.enable && bp.enable) {
    # Use the stock target API to clear 1.24's stale disabled-health state.
    postStart = ''
      ${pkgs.python3}/bin/python3 ${./reconcile-health.py} ${lib.escapeShellArgs [
        "--endpoint"
        bp.endpoint
        "--api-key-file"
        config.sops.secrets.${bp.apiKeySopsPath}.path
        "--org-id"
        bp.orgId
        "--resource"
        "cache"
        "--host"
        tunnelHost
        "--port"
        (toString config.workloads.pangolinResources.cache.targetPort)
      ]}
    '';
    # Restart after daemon-reload so activation cannot reuse the old unit.
    stopIfChanged = false;
    restartTriggers = [./reconcile-health.py];
  };
}
