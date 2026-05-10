# Personal blog namespace.
{ ... }:

{
  imports = [
    ./apps/whoami
  ];

  services.k3s.manifests.blog-ns.content = {
    apiVersion = "v1";
    kind = "Namespace";
    metadata.name = "blog";
  };
}
