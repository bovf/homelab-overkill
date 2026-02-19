{ lib, ... }:
with lib;
{
  imports = [
    ./namespace
  ];

  options.workloads = {
    enable = mkEnableOption "Application workloads";

    # ---------------------------------------------------------------------------
    # Pangolin instances
    # One entry per newt deployment (name = node name, e.g. "engineer").
    # Populated by workloads/namespace/pangolin/apps/newt/instances.nix.
    # ---------------------------------------------------------------------------
    pangolinInstances = mkOption {
      type = types.attrsOf (types.submodule {
        options = {
          endpointKey = mkOption {
            type        = types.str;
            description = "SOPS key path for the Pangolin endpoint URL.";
          };
          idKey = mkOption {
            type        = types.str;
            description = "SOPS key path for the Newt ID.";
          };
          secretKey = mkOption {
            type        = types.str;
            description = "SOPS key path for the Newt secret.";
          };
          siteIdKey = mkOption {
            type        = types.str;
            description = "SOPS key path for the Pangolin site ID (used in blueprint targets).";
          };
        };
      });
      default     = {};
      description = "Map of Pangolin/Newt instances keyed by node name.";
    };

    # ---------------------------------------------------------------------------
    # Pangolin resources
    # One entry per service exposed through Pangolin.
    # Each app owns its entry via its pangolin-blueprint.nix file.
    # The blueprint aggregator (pangolin/apps/newt/blueprint.nix) auto-discovers
    # all entries and renders one K8s Secret per newtInstance.
    # ---------------------------------------------------------------------------
    pangolinResources = mkOption {
      type = types.attrsOf (types.submodule {
        options = {
          name = mkOption {
            type        = types.str;
            description = "Human-readable display name (visible in repo, not a secret).";
          };
          protocol = mkOption {
            type    = types.enum [ "http" "https" ];
            default = "http";
          };
          domainKey = mkOption {
            type        = types.str;
            description = "SOPS key path for the full domain, e.g. 'pangolin/resources/jellyfin/domain'.";
          };
          enabled = mkOption {
            type    = types.bool;
            default = false;
          };
          ssoEnabled = mkOption {
            type    = types.bool;
            default = true;
          };
          targetHostname = mkOption {
            type        = types.str;
            default     = "traefik.kube-system.svc.cluster.local";
            description = "Cluster-internal hostname of the backing service. Not a secret.";
          };
          targetMethod = mkOption {
            type    = types.enum [ "http" "https" ];
            default = "https";
          };
          targetPort = mkOption {
            type    = types.int;
            default = 443;
          };
          newtInstance = mkOption {
            type        = types.str;
            description = "pangolinInstances key this resource is routed through (= node name).";
          };
        };
      });
      default     = {};
      description = "Map of services exposed through Pangolin, keyed by resource identifier.";
    };
  };
}
