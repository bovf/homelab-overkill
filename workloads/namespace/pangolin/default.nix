# Pangolin namespace entrypoint
{ ... }:

{
  imports = [
    # Import apps with their entrypoints
    ./apps/newt
  ];
  
  # Define k3s namespace manifest
  services.k3s.manifests.pangolin-ns.content = {
    apiVersion = "v1";
    kind = "Namespace";
    metadata = { name = "pangolin"; };
  };
}
