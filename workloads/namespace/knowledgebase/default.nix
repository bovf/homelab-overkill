{ ... }:

{
  imports = [
    ./apps/ms-researcher-kb
  ];

  services.k3s.manifests.knowledgebase-ns.content = {
    apiVersion = "v1";
    kind = "Namespace";
    metadata.name = "knowledgebase";
  };
}
