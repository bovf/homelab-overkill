{ ... }:

{
  imports = [
    ./apps/gitlab
  ];

  services.k3s.manifests.gitlab-ns.content = {
    apiVersion = "v1";
    kind = "Namespace";
    metadata.name = "cicd";
  };
}
