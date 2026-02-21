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
  inherit (lib) concatStringsSep mapAttrsToList groupBy;

  resources  = config.workloads.pangolinResources;
  instances  = config.workloads.pangolinInstances;

  byInstance =
    groupBy (r: r.newtInstance)
      (mapAttrsToList (key: v: v // { _key = key; }) resources);

  indent = str: 
    let lines = lib.splitString "\n" str;
    in concatStringsSep "\n" (map (line: if line == "" then line else "      " + line) lines);

  renderHttpResource = r: indent ''
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

  renderTcpUdpResource = r: indent ''
${r._key}:
  name: ${r.name}
  protocol: ${r.protocol}
  proxy-port: ${toString r.proxyPort}
  enabled: ${if r.enabled then "true" else "false"}
  targets:
    - site: ${config.sops.placeholder.${instances.${r.newtInstance}.siteIdKey}}
      hostname: ${r.targetHostname}
      port: ${toString r.targetPort}
'';

  renderResource = r:
    if r.protocol == "http" || r.protocol == "https"
    then renderHttpResource r
    else renderTcpUdpResource r;

  resourcesYaml = rs: concatStringsSep "\n" (map renderResource rs);

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
        ${resourcesYaml instanceResources}
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
