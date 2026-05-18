# MetalLB L2-mode LoadBalancer. Replaces k3s's built-in klipper-lb.
{ lib, ... }:
with lib;
{
  imports = [
    ./helm.nix
    ./pools.nix
    ./k3s.nix
  ];

  options.services.metallb = {
    enable = mkEnableOption "MetalLB L2-mode LoadBalancer";

    namespace = mkOption {
      type        = types.str;
      default     = "metallb-system";
      description = "Namespace MetalLB runs in.";
    };

    chartVersion = mkOption {
      type        = types.str;
      default     = "0.14.9";
      description = "MetalLB helm chart version.";
    };

    pool = mkOption {
      description = "Single IPAddressPool + L2Advertisement configuration.";
      type = types.submodule {
        options = {
          name = mkOption {
            type    = types.str;
            default = "lan-pool";
          };
          addresses = mkOption {
            type        = types.listOf types.str;
            description = "CIDR ranges or IP-IP ranges MetalLB allocates from.";
            example     = [ "192.0.2.10/32" "192.168.2.0/24" ];
          };
        };
      };
    };
  };
}
