{ config, lib, ... }:
with lib;
let
  cfg = config.services.metallb;
in {
  config = mkIf cfg.enable {
    services.k3s.manifests.metallb-pools.content = [
      {
        apiVersion = "metallb.io/v1beta1";
        kind       = "IPAddressPool";
        metadata = {
          name      = cfg.pool.name;
          namespace = cfg.namespace;
        };
        spec = {
          addresses     = cfg.pool.addresses;
          # Skip .0 / .255 of any /24 in the pool.
          avoidBuggyIPs = true;
        };
      }
      {
        apiVersion = "metallb.io/v1beta1";
        kind       = "L2Advertisement";
        metadata = {
          name      = "${cfg.pool.name}-l2";
          namespace = cfg.namespace;
        };
        spec = {
          ipAddressPools = [ cfg.pool.name ];
        };
      }
    ];
  };
}
