{ lib, ... }:
with lib;
{
  imports = [
    ./namespace
    ./lib/lan-services.nix
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
            type    = types.enum [ "http" "https" "tcp" "udp" ];
            default = "http";
          };
          proxyPort = mkOption {
            type        = types.nullOr types.int;
            default     = null;
            description = "Port exposed on Pangolin server (TCP/UDP). Use proxyPortKey instead to keep the port in SOPS.";
          };
          proxyPortKey = mkOption {
            type        = types.nullOr types.str;
            default     = null;
            description = "SOPS key path for the proxy port (TCP/UDP). Mutually exclusive with proxyPort.";
          };
          domainKey = mkOption {
            type        = types.nullOr types.str;
            default     = null;
            description = "SOPS key path for the full domain (HTTP only). E.g. 'pangolin/resources/jellyfin/domain'.";
          };
          enabled = mkOption {
            type    = types.bool;
            default = false;
          };
          ssoEnabled = mkOption {
            type        = types.bool;
            default     = true;
            description = "Enable SSO authentication. Only for HTTP resources.";
          };
          rules = mkOption {
            type    = types.listOf (types.submodule {
              options = {
                priority = mkOption {
                  type        = types.nullOr types.int;
                  default     = null;
                  description = "Processing priority of the rule. Auto-assigned if null.";
                };
                action = mkOption {
                  type        = types.enum [ "allow" "deny" "pass" ];
                  description = "Rule action.";
                };
                match = mkOption {
                  type        = types.enum [ "ip" "cidr" "country" "path" ];
                  description = "Match type.";
                };
                value = mkOption {
                  type        = types.str;
                  description = "Value to match against (e.g. country code, IP, CIDR, path).";
                };
              };
            });
            default     = [];
            description = "Access control rules for the resource (HTTP only).";
          };
          targetHostname = mkOption {
            type        = types.str;
            default     = "traefik.kube-system.svc.cluster.local";
            description = "Cluster-internal hostname of the backing service. Not a secret.";
          };
          targetMethod = mkOption {
            type        = types.nullOr (types.enum [ "http" "https" ]);
            default     = "https";
            description = "Protocol method for HTTP resources. Not used for TCP/UDP.";
          };
          targetPort = mkOption {
            type    = types.int;
            default = 443;
          };
          newtInstance = mkOption {
            type        = types.str;
            description = "pangolinInstances key this resource is routed through (= node name).";
          };
          lanIP = mkOption {
            type        = types.nullOr types.str;
            default     = null;
            description = "MetalLB-pinned LAN IP for the generated <key>-lan LoadBalancer Service.";
          };
          lanNamespace = mkOption {
            type        = types.str;
            default     = "kube-system";
            description = "Namespace for the generated <key>-lan Service.";
          };
          viaKernelWg = mkOption {
            type        = types.bool;
            default     = false;
            description = "Route this resource via the host-side kernel-WG client instead of the in-cluster newt pod.";
          };
          healthcheck = mkOption {
            type = types.nullOr (types.submodule {
              options = {
                hostname = mkOption {
                  type        = types.nullOr types.str;
                  default     = null;
                  description = "Defaults to targetHostname. Pangolin can't set a Host header so this should usually be the backend service, not traefik.";
                };
                port = mkOption {
                  type        = types.nullOr types.int;
                  default     = null;
                  description = "Port to probe. Defaults to targetPort when null.";
                };
                path = mkOption {
                  type        = types.str;
                  default     = "/";
                  description = "HTTP path to probe (HTTP resources only).";
                };
              };
            });
            default     = null;
            description = "Optional target healthcheck. When null, no healthcheck is emitted.";
          };
        };
      });
      default     = {};
      description = "Map of services exposed through Pangolin, keyed by resource identifier.";
    };

    # Each app declares its entry in a per-workload local-dns.nix file;
    # the pihole chart aggregates them into FTLCONF_dns_hosts.
    localDnsRecords = mkOption {
      type = types.attrsOf (types.submodule {
        options = {
          host = mkOption {
            type        = types.str;
            description = "FQDN to publish. Usually a sops.placeholder.";
          };
          ip = mkOption {
            type        = types.str;
            description = "IPv4 address to resolve `host` to on the LAN.";
          };
        };
      });
      default     = {};
      description = "LAN-side DNS A records published by pihole.";
    };

    # ---------------------------------------------------------------------------
    # Uptime Kuma monitors
    # One entry per workload that wants to be monitored. The init-job in
    # workloads/namespace/monitoring/apps/uptime-kuma/init-job.nix walks
    # this attrset, syncs Kuma, builds the "homelab" status page, and
    # deletes any monitors it previously created that aren't declared
    # here anymore.
    # ---------------------------------------------------------------------------
    uptimeMonitors = mkOption {
      type = types.attrsOf (types.submodule {
        options = {
          name = mkOption {
            type        = types.str;
            description = "Display name in Kuma + the dashboard SERVICES grid.";
          };
          type = mkOption {
            type    = types.enum [ "http" "port" ];
            default = "http";
            description = "Probe type. http = full HTTP request; port = TCP handshake.";
          };

          # ── HTTP target — exactly one of domainKey or url ────────────
          domainKey = mkOption {
            type        = types.nullOr types.str;
            default     = null;
            description = "SOPS key for a *.dobryops.com hostname. Mutually exclusive with url.";
          };
          url = mkOption {
            type        = types.nullOr types.str;
            default     = null;
            description = "Hardcoded URL (e.g. cluster-internal http://svc.ns.svc.cluster.local:8080).";
          };
          path = mkOption {
            type        = types.str;
            default     = "/";
            description = "Path appended to the resolved domain/url. HTTP monitors only.";
          };

          # ── TCP target — required when type = port ───────────────────
          host = mkOption {
            type        = types.nullOr types.str;
            default     = null;
            description = "Host to TCP-dial. port monitors only.";
          };
          port = mkOption {
            type        = types.nullOr types.int;
            default     = null;
            description = "Port to TCP-dial. port monitors only.";
          };

          # ── tuning ────────────────────────────────────────────────────
          interval = mkOption {
            type    = types.int;
            default = 60;
          };
          retryInterval = mkOption {
            type    = types.int;
            default = 20;
          };
          maxretries = mkOption {
            type    = types.int;
            default = 3;
          };
          acceptedStatusCodes = mkOption {
            type    = types.listOf types.str;
            default = [ "200-299" "301" "302" ];
            description = "302 covers Pangolin SSO challenge for off-LAN probes.";
          };

          # ── status page presentation ─────────────────────────────────
          group = mkOption {
            type        = types.str;
            default     = "Services";
            description = "Section name on the public status page. 'Private' for cluster-internal-only monitors.";
          };
          tags = mkOption {
            type        = types.listOf types.str;
            default     = [];
            description = "Free-form tags surfaced in Kuma's monitor list.";
          };
          enabled = mkOption {
            type    = types.bool;
            default = true;
          };
        };
      });
      default     = {};
      description = "Per-workload uptime monitors. Aggregated by the uptime-kuma init-job.";
    };
  };
}
