# Intel device plugins namespace entrypoint
{ ... }:

{
  imports = [
    # Import apps with their entrypoints
    ./apps/intel-device-plugins-gpu
    ./apps/intel-device-plugins-operator
  ];
  
  # Define k3s namespace manifest
  services.k3s.manifests.intel-device-plugins-ns.content = {
    apiVersion = "v1";
    kind = "Namespace";
    metadata = { name = "intel-device-plugins"; };
  };
}
