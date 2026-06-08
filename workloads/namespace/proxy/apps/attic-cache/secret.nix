{ config, ... }:

{
  sops.secrets."attic/server_token_rs256_secret_base64" = {};
  sops.secrets."attic/admin_token" = {};
  sops.secrets."attic/ci_push_token" = {};

  sops.templates."attic-cache/secret.yaml" = {
    content = ''
      apiVersion: v1
      kind: Secret
      metadata:
        name: attic-cache-secret
        namespace: proxy
        labels:
          app: attic-cache
      type: Opaque
      stringData:
        ATTIC_SERVER_TOKEN_RS256_SECRET_BASE64: "${config.sops.placeholder."attic/server_token_rs256_secret_base64"}"
        ATTIC_ADMIN_TOKEN: "${config.sops.placeholder."attic/admin_token"}"
        ATTIC_TOKEN: "${config.sops.placeholder."attic/ci_push_token"}"
    '';
    path = "/var/lib/rancher/k3s/server/manifests/attic-cache-secret.yaml";
    owner = "root";
    group = "root";
    mode = "0644";
  };
}
