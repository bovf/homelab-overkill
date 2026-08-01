{...}: {
  services.k3s.manifests.version-checker-prometheusrule.content = {
    apiVersion = "monitoring.coreos.com/v1";
    kind = "PrometheusRule";
    metadata = {
      name = "version-checker";
      namespace = "monitoring";
      labels."app.kubernetes.io/name" = "version-checker";
    };
    spec.groups = [
      {
        name = "version-checker";
        rules = [
          {
            alert = "ImageOutOfDate";
            # version_checker_is_latest_version == 1 when on latest, 0 when not.
            # Fires only after 72h of continuous drift to debounce transient
            # registry hiccups, chart lag, and patch releases during the
            # rolling window.
            expr = ''
              (
                version_checker_is_latest_version{
                  image!="rancher/klipper-helm",
                  image!="rancher/mirrored-coredns-coredns",
                  # Owned by K3s's bundled manifests/chart. Traefik >3.7.4
                  # currently fails the bundled chart's schema validation.
                  image!="rancher/mirrored-metrics-server",
                  image!="rancher/mirrored-library-traefik",
                  # MetalLB 0.16.1 (current chart) pins FRR 10.6.1.
                  image!="quay.io/frrouting/frr",
                  image!="quay.io/prometheus-operator/prometheus-config-reloader",
                  image!="quay.io/prometheus-operator/prometheus-operator",
                  image!="postgres",
                  image!="docker.io/bitnamilegacy/redis",
                  image!="docker.io/bitnamilegacy/redis-exporter",
                  container_type!="init",
                  latest_version!~"^(sha-|snapshot|unstable|nightly|develop|dev|master|pr|latest-snapshot).*$",
                  latest_version!~".*(-dev|-pr|_beta).*$",
                  latest_version!~"^[0-9]{8,}$"
                } == 0
              )
              and on(namespace, pod)
              (kube_pod_status_phase{phase="Running"} == 1)
            '';
            "for" = "72h";
            labels = {
              severity = "warning";
            };
            annotations = {
              summary = "{{ $labels.namespace }}/{{ $labels.pod }} container {{ $labels.container }} is outdated";
              description = "Running {{ $labels.current_version }}, latest upstream is {{ $labels.latest_version }}.";
            };
          }
        ];
      }
    ];
  };
}
