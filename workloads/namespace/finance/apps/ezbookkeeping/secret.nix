{ config, ... }:

{
  # Keys are named to match the EBK_ env vars so the helm chart can pull
  # them in verbatim via `envFrom.secretRef`.
  sops.templates."finance/ezbookkeeping-credentials.yaml" = {
    content = ''
      apiVersion: v1
      kind: Secret
      metadata:
        name: ezbookkeeping-credentials
        namespace: finance
      type: Opaque
      stringData:
        EBK_DATABASE_PASSWD: "${config.sops.placeholder."database/postgres/ezbookkeeping/password"}"
        EBK_SECURITY_SECRET_KEY: "${config.sops.placeholder."finance/ezbookkeeping/secret_key"}"
    '';
    path  = "/var/lib/rancher/k3s/server/manifests/ezbookkeeping-credentials.yaml";
    owner = "root";
    group = "root";
    mode  = "0644";
  };
}
