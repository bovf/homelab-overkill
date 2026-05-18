# Pangolin kernel-WG client. Resources flagged viaKernelWg=true in
# workloads.pangolinResources route through this host-side tunnel
# instead of the in-cluster newt pod.
{ lib, ... }:
with lib;
{
  imports = [
    ./wg.nix
    ./nat.nix
    ./blueprint.nix
    ./secrets.nix
  ];

  options.services.pangolin-kwg = {
    enable = mkEnableOption "Pangolin kernel-WG client";

    instance = mkOption {
      type        = types.str;
      description = "pangolinInstances key for this kernel-WG site.";
    };

    interfaceName = mkOption {
      type        = types.str;
      default     = "pangolin-kwg";
      description = "wg-quick interface name.";
    };

    site = mkOption {
      description = "WG tunnel parameters issued by the Basic WireGuard pangolin site.";
      type = types.submodule {
        options = {
          privateKeySopsPath = mkOption {
            type        = types.str;
            description = "SOPS secret path holding this host's WG private key.";
          };
          siteIdSopsPath = mkOption {
            type        = types.str;
            description = "SOPS secret path holding the pangolin site ID, used in blueprint targets[].site.";
          };
          peerPublicKey = mkOption {
            type        = types.str;
            description = "Gerbil's WG public key.";
          };
          endpoint = mkOption {
            type        = types.str;
            description = "Gerbil's WG endpoint host:port.";
          };
          address = mkOption {
            type        = types.listOf types.str;
            description = "Tunnel-side address(es), CIDR form.";
          };
          allowedIPs = mkOption {
            type        = types.listOf types.str;
            description = "AllowedIPs for the gerbil peer.";
          };
          mtu = mkOption {
            type        = types.int;
            default     = 1280;
            # Matches gerbil's pinned MTU to avoid fragmentation /
            # burst-stalls (fosrl/pangolin#512).
            description = "Tunnel MTU.";
          };
          listenPort = mkOption {
            type        = types.nullOr types.int;
            default     = null;
            description = "Local UDP listen port. Null = kernel picks one.";
          };
          persistentKeepalive = mkOption {
            type        = types.int;
            default     = 25;
            description = "Seconds between keep-alive packets.";
          };
        };
      };
    };

    natRules = mkOption {
      default     = {};
      description = "Per-resource DNAT rules from tunnel ingress to backends.";
      type = types.attrsOf (types.submodule {
        options = {
          listenPort = mkOption {
            type        = types.int;
            description = "Tunnel-side destination port.";
          };
          target = mkOption {
            type        = types.str;
            description = "Backend address as `<host>:<port>`.";
          };
          protocol = mkOption {
            type    = types.enum [ "tcp" "udp" ];
            default = "tcp";
          };
        };
      });
    };

    blueprintSync = mkOption {
      description = "PUT the rendered blueprint to pangolin's REST API on every rebuild.";
      type = types.submodule {
        options = {
          enable = mkOption {
            type    = types.bool;
            default = true;
          };
          orgId = mkOption {
            type        = types.nullOr types.str;
            default     = null;
            description = "Pangolin organization ID.";
          };
          endpoint = mkOption {
            type        = types.nullOr types.str;
            default     = null;
            description = "Integration API base URL (e.g. https://api.dobryops.com).";
          };
          apiKeySopsPath = mkOption {
            type        = types.str;
            default     = "pangolin/api-keys/blueprint-sync";
            description = "SOPS secret path for the Integration API key (`<key_id>.<key_secret>`).";
          };
        };
      };
      default = {};
    };
  };
}
