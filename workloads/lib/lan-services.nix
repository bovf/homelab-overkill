# Emits a `<key>-lan` LoadBalancer Service per pangolinResource with a
# pinned lanIP, selecting traefik on 80/443 for LAN-side Host routing.
{ config, lib, ... }:
with lib;
let
  inherit (lib) filterAttrs mapAttrs';

  withLan = filterAttrs
    (_: r: r.lanIP != null)
    config.workloads.pangolinResources;

  # k3s's traefik chart names the helm release `traefik-${namespace}`.
  traefikSelector = {
    "app.kubernetes.io/name"     = "traefik";
    "app.kubernetes.io/instance" = "traefik-kube-system";
  };

  # Resource keys may contain underscores (e.g. minio_console) since they
  # double as Pangolin niceIds — but Kubernetes Service names must be
  # DNS-1035 labels (no underscores). Sanitise before deriving the name,
  # otherwise the manifest silently fails to apply and the LAN IP is dead.
  mkLanService = name: r:
  let
    svc = "${replaceStrings [ "_" ] [ "-" ] name}-lan";
  in {
    name  = "${name}-lan-service";
    value.content = {
      apiVersion = "v1";
      kind       = "Service";
      metadata = {
        name      = svc;
        namespace = r.lanNamespace;
        annotations = {
          # Allow hand-rolled Services to share this IP for ports the
          # traefik-fronted Service doesn't cover (e.g. raw TCP for SSH).
          "metallb.io/allow-shared-ip" = svc;
        };
        labels    = {
          app                               = svc;
          "homelab.dobryops.com/lan-target" = name;
        };
      };
      spec = {
        type           = "LoadBalancer";
        loadBalancerIP = r.lanIP;
        selector       = traefikSelector;
        ports = [
          { name = "web";       port = 80;  targetPort = 8000; protocol = "TCP"; }
          { name = "websecure"; port = 443; targetPort = 8443; protocol = "TCP"; }
        ];
      };
    };
  };
in {
  config.services.k3s.manifests =
    mapAttrs' mkLanService withLan;
}
