{config, ...}: {
  sops.secrets."gitlab/nix_cache_runner_token" = {};

  sops.templates."gitlab/nix-cache-runner-secret.yaml" = {
    content = ''
      apiVersion: v1
      kind: Secret
      metadata:
        name: gitlab-nix-cache-runner-secret
        namespace: cicd
      type: Opaque
      stringData:
        runner-token: "${config.sops.placeholder."gitlab/nix_cache_runner_token"}"
        # The GitLab runner chart still projects this key for compatibility,
        # even when using modern glrt-* runner authentication tokens.
        runner-registration-token: ""
    '';
    path = "/var/lib/rancher/k3s/server/manifests/gitlab-nix-cache-runner-secret.yaml";
    owner = "root";
    group = "root";
    mode = "0644";
  };
}
