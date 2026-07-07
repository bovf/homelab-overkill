{config, ...}: {
  sops.secrets."database/postgres/sparkyfitness/password" = {};
  sops.secrets."database/postgres/sparkyfitness/app_password" = {};
  sops.secrets."sparkyfitness/api_encryption_key" = {};
  sops.secrets."sparkyfitness/better_auth_secret" = {};

  sops.templates."health/sparkyfitness-secret.yaml" = {
    content = ''
      apiVersion: v1
      kind: Secret
      metadata:
        name: sparkyfitness-secrets
        namespace: health
      type: Opaque
      stringData:
        SPARKY_FITNESS_DB_PASSWORD: "${config.sops.placeholder."database/postgres/sparkyfitness/password"}"
        SPARKY_FITNESS_APP_DB_PASSWORD: "${config.sops.placeholder."database/postgres/sparkyfitness/app_password"}"
        SPARKY_FITNESS_API_ENCRYPTION_KEY: "${config.sops.placeholder."sparkyfitness/api_encryption_key"}"
        BETTER_AUTH_SECRET: "${config.sops.placeholder."sparkyfitness/better_auth_secret"}"
    '';
    path = "/var/lib/rancher/k3s/server/manifests/sparkyfitness-secret.yaml";
    owner = "root";
    group = "root";
    mode = "0644";
  };
}
