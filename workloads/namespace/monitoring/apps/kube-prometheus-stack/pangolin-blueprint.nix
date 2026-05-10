{ nodeName, ... }:

{
  # Grafana — bundled in kube-prometheus-stack
  workloads.pangolinResources.grafana = {
    name           = "Grafana Dashboard";
    protocol       = "http";
    domainKey      = "pangolin/resources/grafana/domain";
    enabled        = true;
    ssoEnabled     = true;
    targetHostname = "traefik.kube-system.svc.cluster.local";
    targetMethod   = "https";
    targetPort     = 443;
    newtInstance   = nodeName;
    healthcheck = {
      hostname = "kube-prometheus-stack-grafana.monitoring.svc.cluster.local";
      # Service port is the chart-overridden 32000 (not the default 80).
      port     = 32000;
      path     = "/api/health";
    };
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
    healthcheck = {
      hostname = "kube-prometheus-stack-prometheus.monitoring.svc.cluster.local";
      port     = 9090;
      path     = "/-/healthy";
    };
  };

  sops.secrets."pangolin/resources/prometheus/domain" = {};

  # Alertmanager — also bundled in kube-prometheus-stack
  workloads.pangolinResources.alertmanager = {
    name           = "Alertmanager";
    protocol       = "http";
    domainKey      = "pangolin/resources/alertmanager/domain";
    enabled        = false;
    ssoEnabled     = true;
    targetHostname = "traefik.kube-system.svc.cluster.local";
    targetMethod   = "https";
    targetPort     = 443;
    newtInstance   = nodeName;
    healthcheck = {
      hostname = "kube-prometheus-stack-alertmanager.monitoring.svc.cluster.local";
      port     = 9093;
      path     = "/-/healthy";
    };
  };

  sops.secrets."pangolin/resources/alertmanager/domain" = {};
}
