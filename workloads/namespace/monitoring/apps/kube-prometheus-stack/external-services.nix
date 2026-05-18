# Sibling Services that only expose the api port (9090/9093). Putting
# externalIPs on the chart's own Service attaches the tunnel IP to the
# config-reloader sidecar's :8080 too, which collides with qbittorrent.
{ ... }:

{
  services.k3s.manifests.prometheus-extip.content = {
    apiVersion = "v1";
    kind       = "Service";
    metadata = {
      name      = "kube-prometheus-stack-prometheus-extip";
      namespace = "monitoring";
      labels = {
        app                              = "prometheus-extip";
        "homelab.dobryops.com/extip-for" = "kube-prometheus-stack-prometheus";
      };
    };
    spec = {
      type        = "ClusterIP";
      externalIPs = [ "100.89.128.16" ];
      selector = {
        "app.kubernetes.io/name"      = "prometheus";
        "operator.prometheus.io/name" = "kube-prometheus-stack-prometheus";
      };
      ports = [
        {
          name       = "http-web";
          port       = 9090;
          targetPort = 9090;
          protocol   = "TCP";
        }
      ];
    };
  };

  services.k3s.manifests.alertmanager-extip.content = {
    apiVersion = "v1";
    kind       = "Service";
    metadata = {
      name      = "kube-prometheus-stack-alertmanager-extip";
      namespace = "monitoring";
      labels = {
        app                              = "alertmanager-extip";
        "homelab.dobryops.com/extip-for" = "kube-prometheus-stack-alertmanager";
      };
    };
    spec = {
      type        = "ClusterIP";
      externalIPs = [ "100.89.128.16" ];
      selector = {
        "app.kubernetes.io/name" = "alertmanager";
        alertmanager             = "kube-prometheus-stack-alertmanager";
      };
      ports = [
        {
          name       = "http-web";
          port       = 9093;
          targetPort = 9093;
          protocol   = "TCP";
        }
      ];
    };
  };
}
