# Monitoring namespace entrypoint
{ ... }:

{
  imports = [
    # Import apps with their entrypoints
    ./apps/kube-prometheus-stack
    ./apps/loki
    ./apps/alloy
    ./apps/intel-gpu-exporter
    ./apps/local-path-du-exporter
    ./apps/version-checker
    ./apps/nova
    ./apps/grafana-dashboards
  ];
  
  # Define k3s namespace manifest
  services.k3s.manifests.monitoring-ns.content = {
    apiVersion = "v1";
    kind = "Namespace";
    metadata = { name = "monitoring"; };
  };
}
