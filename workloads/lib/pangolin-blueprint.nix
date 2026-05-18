# Shared blueprint YAML renderer. Consumed by both the newt blueprint
# aggregator and the pangolin-kwg blueprint sync.
{ config, lib, instances }:

let
  inherit (lib) concatStringsSep optionalString;

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

  # Hand-built string (not '' '') so Nix's whitespace stripping doesn't
  # shift the indent — healthcheck must nest inside the target list item.
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

in {
  inherit
    indent
    renderRule renderRules
    renderHealthcheck
    proxyPortValue
    renderHttpResource renderTcpUdpResource
    renderResource resourcesYaml;
}
