{ ... }:

{
  imports = [
    ./apps/reactive-resume
    ./apps/chrome
  ];

  services.k3s.manifests.resume-ns.content = {
    apiVersion = "v1";
    kind = "Namespace";
    metadata.name = "resume";
  };
}
