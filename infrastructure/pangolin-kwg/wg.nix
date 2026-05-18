{ config, lib, ... }:
with lib;
let
  cfg = config.services.pangolin-kwg;
in {
  config = mkIf cfg.enable {
    boot.kernelModules = [ "wireguard" ];

    # Loose RPF — DNAT'd return packets leave via a different interface
    # than the WG ingress; strict rp_filter would drop them.
    boot.kernel.sysctl."net.ipv4.conf.all.rp_filter" = mkForce 2;

    networking.firewall.allowedUDPPorts =
      lib.optional (cfg.site.listenPort != null) cfg.site.listenPort;

    networking.wg-quick.interfaces.${cfg.interfaceName} = {
      address        = cfg.site.address;
      mtu            = cfg.site.mtu;
      listenPort     = cfg.site.listenPort;
      privateKeyFile = config.sops.secrets.${cfg.site.privateKeySopsPath}.path;
      peers = [{
        publicKey           = cfg.site.peerPublicKey;
        endpoint            = cfg.site.endpoint;
        allowedIPs          = cfg.site.allowedIPs;
        persistentKeepalive = cfg.site.persistentKeepalive;
      }];
    };
  };
}
