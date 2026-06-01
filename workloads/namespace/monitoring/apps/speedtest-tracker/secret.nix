# speedtest-tracker is a Laravel app — APP_KEY must be exactly 32 random
# bytes base64'd, prefixed with `base64:` (Laravel convention). Generate:
#   echo "base64:$(openssl rand -base64 32)"
{ config, ... }:

{
  sops.templates."speedtest-tracker/env.yaml" = {
    content = ''
      apiVersion: v1
      kind: Secret
      metadata:
        name: speedtest-tracker-env
        namespace: monitoring
      type: Opaque
      stringData:
        APP_KEY: "${config.sops.placeholder."speedtest/app_key"}"
    '';
    path  = "/var/lib/rancher/k3s/server/manifests/speedtest-tracker-env.yaml";
    owner = "root";
    group = "root";
    mode  = "0644";
  };
}
