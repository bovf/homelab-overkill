
# Monitoring namespace entrypoint
{ ... }:

{
  imports = [
    # Import apps with their entrypoints
    ./apps/kube-prometheus-stack
  ];
  
  # Define k3s namespace manifest
  services.k3s.manifests.monitoring-ns.content = {
    apiVersion = "v1";
    kind = "Namespace";
    metadata = { name = "monitoring"; };
  };
}
