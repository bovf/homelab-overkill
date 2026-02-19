{ nodeName, ... }:

{
  # Grafana — bundled in kube-prometheus-stack
  workloads.pangolinResources.grafana = {
    name           = "Grafana Dashboard";
    protocol       = "http";
    domainKey      = "pangolin/resources/grafana/domain";
    enabled        = false;
    ssoEnabled     = true;
    targetHostname = "traefik.kube-system.svc.cluster.local";
    targetMethod   = "https";
    targetPort     = 443;
    newtInstance   = nodeName;
  };

  sops.secrets."pangolin/resources/grafana/domain" = {};

  # Prometheus — also bundled in kube-prometheus-stack
  workloads.pangolinResources.prometheus = {
    name           = "Prometheus";
    protocol       = "http";
    domainKey      = "pangolin/resources/prometheus/domain";
    enabled        = false;
    ssoEnabled     = true;
    targetHostname = "traefik.kube-system.svc.cluster.local";
    targetMethod   = "https";
    targetPort     = 443;
    newtInstance   = nodeName;
  };

  sops.secrets."pangolin/resources/prometheus/domain" = {};
}
