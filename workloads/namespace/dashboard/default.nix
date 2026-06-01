# Dashboard namespace — homepage launcher (glance) + its in-cluster search
# backend (searxng). Glance lands here next commit.
{ ... }:

{
  imports = [
    ./apps/searxng
  ];

  services.k3s.manifests.dashboard-ns.content = {
    apiVersion = "v1";
    kind = "Namespace";
    metadata.name = "dashboard";
  };
}
