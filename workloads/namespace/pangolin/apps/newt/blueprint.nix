# Pangolin blueprint aggregator.
#
# Auto-discovers every workloads.pangolinResources entry, groups them by
# newtInstance, and renders one K8s Secret per instance.  Each secret is
# written to /var/lib/rancher/k3s/server/manifests/ so k3s applies it
# automatically before the newt pod starts.
#
# Domain values and the site ID are injected via sops.placeholder — they
# are never written to the Nix store or the Git repository in plain text.
{ config, lib, ... }:

let
  inherit (lib) concatStringsSep mapAttrsToList attrValues groupBy;

  resources  = config.workloads.pangolinResources;
  instances  = config.workloads.pangolinInstances;

  # Group resource attribute sets by their newtInstance field.
  # Result: { "engineer" = [ { key = "jellyfin"; name = ...; ... } ... ]; }
  byInstance =
    groupBy (r: r.newtInstance)
      (mapAttrsToList (key: v: v // { _key = key; }) resources);

  # Render one YAML resource block inside the blueprint.
  renderResource = r: ''
              ${r._key}:
                name: ${r.name}
                protocol: ${r.protocol}
                full-domain: ${config.sops.placeholder.${r.domainKey}}
                enabled: ${if r.enabled then "true" else "false"}
                auth:
                  sso-enabled: ${if r.ssoEnabled then "true" else "false"}
                targets:
                  - site: ${config.sops.placeholder.${instances.${r.newtInstance}.siteIdKey}}
                    hostname: ${r.targetHostname}
                    method: ${r.targetMethod}
                    port: ${toString r.targetPort}
                headers:
                  - name: Host
                    value: ${config.sops.placeholder.${r.domainKey}}
  '';

  # Render the full sops.templates entry for one instance.
  # Returns an attrset suitable for merging into sops.templates.
  renderInstanceTemplate = instanceName: instanceResources: {
    "pangolin/blueprint-${instanceName}.yaml" = {
      content = ''
        apiVersion: v1
        kind: Secret
        metadata:
          name: pangolin-blueprint-${instanceName}
          namespace: pangolin
        type: Opaque
        stringData:
          blueprint.yaml: |
            public-resources:
        ${concatStringsSep "" (map renderResource instanceResources)}
      '';
      path  = "/var/lib/rancher/k3s/server/manifests/pangolin-blueprint-${instanceName}.yaml";
      owner = "root";
      group = "root";
      mode  = "0644";
    };
  };

in
{
  sops.templates =
    lib.mkMerge
      (mapAttrsToList renderInstanceTemplate byInstance);
}
