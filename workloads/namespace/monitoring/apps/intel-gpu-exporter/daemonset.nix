{ ... }:

{
  services.k3s.manifests.intel-gpu-exporter-daemonset.content = {
    apiVersion = "apps/v1";
    kind = "DaemonSet";
    metadata = {
      name = "intel-gpu-exporter";
      namespace = "monitoring";
      labels = {
        "app.kubernetes.io/name" = "intel-gpu-exporter";
      };
    };
    spec = {
      selector.matchLabels."app.kubernetes.io/name" = "intel-gpu-exporter";
      template = {
        metadata.labels."app.kubernetes.io/name" = "intel-gpu-exporter";
        spec = {
          # intel_gpu_top reads PMU counters via perf_event_open and walks
          # /proc to attribute usage; needs the host PID namespace + a
          # privileged container.
          hostPID = true;
          containers = [{
            name = "exporter";
            image = "ghcr.io/clambin/intel-gpu-exporter:0.7.0";
            ports = [{
              name = "metrics";
              containerPort = 9100;
              protocol = "TCP";
            }];
            securityContext = {
              privileged = true;
            };
            volumeMounts = [{
              name = "dri";
              mountPath = "/dev/dri";
            }];
            # No CPU limit — intel_gpu_top polls PMU counters across every
            # engine on a 5s interval and was hitting 66% throttle at 200m.
            resources = {
              requests = { cpu = "20m"; memory = "32Mi"; };
              limits   = { memory = "128Mi"; };
            };
          }];
          volumes = [{
            name = "dri";
            hostPath = {
              path = "/dev/dri";
              type = "Directory";
            };
          }];
        };
      };
    };
  };
}
