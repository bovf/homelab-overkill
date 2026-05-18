{ nodeName, ... }:

{
  workloads.pangolinResources.grafana = {
    name           = "Grafana Dashboard";
    protocol       = "http";
    domainKey      = "pangolin/resources/grafana/domain";
    enabled        = true;
    ssoEnabled     = true;
    targetHostname = "kube-prometheus-stack-grafana.monitoring.svc.cluster.local";
    targetMethod   = "http";
    targetPort     = 32000;
    newtInstance   = "engineer-kernel";
    viaKernelWg    = true;
    lanIP          = "192.168.2.30";
  };

  sops.secrets."pangolin/resources/grafana/domain" = {};

  workloads.pangolinResources.prometheus = {
    name           = "Prometheus";
    protocol       = "http";
    domainKey      = "pangolin/resources/prometheus/domain";
    enabled        = true;
    ssoEnabled     = true;
    targetHostname = "kube-prometheus-stack-prometheus.monitoring.svc.cluster.local";
    targetMethod   = "http";
    targetPort     = 9090;
    newtInstance   = "engineer-kernel";
    viaKernelWg    = true;
    lanIP          = "192.168.2.31";
  };

  sops.secrets."pangolin/resources/prometheus/domain" = {};

  workloads.pangolinResources.alertmanager = {
    name           = "Alertmanager";
    protocol       = "http";
    domainKey      = "pangolin/resources/alertmanager/domain";
    enabled        = false;
    ssoEnabled     = true;
    targetHostname = "kube-prometheus-stack-alertmanager.monitoring.svc.cluster.local";
    targetMethod   = "http";
    targetPort     = 9093;
    newtInstance   = "engineer-kernel";
    viaKernelWg    = true;
    lanIP          = "192.168.2.32";
  };

  sops.secrets."pangolin/resources/alertmanager/domain" = {};
}
