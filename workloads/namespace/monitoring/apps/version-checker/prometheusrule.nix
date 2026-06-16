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
            # Fires only after 24h of continuous drift to debounce transient
            # registry hiccups during the rolling window.
            expr = ''
              version_checker_is_latest_version{
                image!="rancher/klipper-helm",
                image!="postgres",
                image!="docker.io/bitnamilegacy/redis",
                image!="docker.io/bitnamilegacy/redis-exporter",
                latest_version!~"^(sha-|snapshot|unstable|nightly|develop|dev|master|pr|latest-snapshot).*$",
                latest_version!~".*(-dev|-pr|_beta).*$",
                latest_version!~"^[0-9]{8,}$"
              } == 0
            '';
            "for" = "24h";
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
