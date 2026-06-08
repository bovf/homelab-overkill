{...}: {
  imports = [
    ./apps/gitlab
    ./apps/gitlab-nix-runner
    ./apps/argocd
    ./apps/reloader
    ./apps/keel
    ./apps/newt
  ];

  services.k3s.manifests.gitlab-ns.content = {
    apiVersion = "v1";
    kind = "Namespace";
    metadata.name = "cicd";
  };
}
