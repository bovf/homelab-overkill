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
  inherit (lib) concatStringsSep mapAttrsToList groupBy optionalString;

  resources  = config.workloads.pangolinResources;
  instances  = config.workloads.pangolinInstances;

  byInstance =
    groupBy (r: r.newtInstance)
      (mapAttrsToList (key: v: v // { _key = key; }) resources);

  indent = str:
    let lines = lib.splitString "\n" str;
    in concatStringsSep "\n" (map (line: if line == "" then line else "      " + line) lines);

  renderRule = rule:
    "  - action: ${rule.action}\n"
    + "    match: ${rule.match}\n"
    + "    value: ${rule.value}\n"
    + optionalString (rule.priority != null) "    priority: ${toString rule.priority}\n";

  renderRules = rules:
    optionalString (rules != [])
      ("  rules:\n" + concatStringsSep "" (map renderRule rules));

  # Indentation matters: the healthcheck block must nest INSIDE the target
  # list item (sibling of `hostname`, `method`, `port`). In the
  # pre-`indent` template those fields sit at 6 spaces; healthcheck:
  # matches, children at 8.
  # Use explicit "..." concat (not a heredoc) so Nix's indented-string
  # whitespace-stripping rules don't silently shift the indent.
  renderHealthcheck = r:
    if r.healthcheck == null then ""
    else
      let
        hc = r.healthcheck;
        hostname = if hc.hostname != null then hc.hostname else r.targetHostname;
        port     = if hc.port     != null then hc.port     else r.targetPort;
      in
        "      healthcheck:\n"
        + "        hostname: ${hostname}\n"
        + "        port: ${toString port}\n"
        + "        path: ${hc.path}\n";

  renderHttpResource = r: indent ''
${r._key}:
  name: ${r.name}
  protocol: ${r.protocol}
  full-domain: ${config.sops.placeholder.${r.domainKey}}
  enabled: ${if r.enabled then "true" else "false"}
  auth:
    sso-enabled: ${if r.ssoEnabled then "true" else "false"}
${renderRules r.rules}  targets:
    - site: ${config.sops.placeholder.${instances.${r.newtInstance}.siteIdKey}}
      hostname: ${r.targetHostname}
      method: ${r.targetMethod}
      port: ${toString r.targetPort}
${renderHealthcheck r}  headers:
    - name: Host
      value: ${config.sops.placeholder.${r.domainKey}}
'';

  proxyPortValue = r:
    if r.proxyPortKey != null
    then config.sops.placeholder.${r.proxyPortKey}
    else toString r.proxyPort;

  renderTcpUdpResource = r: indent ''
${r._key}:
  name: ${r.name}
  protocol: ${r.protocol}
  proxy-port: ${proxyPortValue r}
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
