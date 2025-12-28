{ ... }:

{
  imports = [
    ./apps/gitlab
    # ./apps/argocd
  ];

  services.k3s.manifests.gitlab-ns.content = {
    apiVersion = "v1";
    kind = "Namespace";
    metadata.name = "cicd";
  };
}
