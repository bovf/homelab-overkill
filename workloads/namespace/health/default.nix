# Health / fitness apps.
{...}: {
  imports = [
    ./apps/sparkyfitness
  ];

  services.k3s.manifests.health-ns.content = {
    apiVersion = "v1";
    kind = "Namespace";
    metadata.name = "health";
  };
}
