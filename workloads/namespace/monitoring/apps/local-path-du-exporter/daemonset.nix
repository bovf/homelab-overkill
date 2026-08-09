{...}: {
  services.k3s.manifests.local-path-du-exporter-daemonset.content = {
    apiVersion = "apps/v1";
    kind = "DaemonSet";
    metadata = {
      name = "local-path-du-exporter";
      namespace = "monitoring";
      labels."app.kubernetes.io/name" = "local-path-du-exporter";
    };
    spec = {
      selector.matchLabels."app.kubernetes.io/name" = "local-path-du-exporter";
      template = {
        metadata.labels."app.kubernetes.io/name" = "local-path-du-exporter";
        spec = {
          containers = [
            {
              name = "exporter";
              image = "docker.io/python:3.14.7@sha256:b5998102f95c4b44edf1e7cb5cecbe1f49e0bf054f345c1db5b854e166e6e17a";
              command = ["python3" "/app/exporter.py"];
              ports = [
                {
                  name = "metrics";
                  containerPort = 9101;
                  protocol = "TCP";
                }
              ];
              env = [
                {
                  name = "STORAGE_PATH";
                  value = "/data/storage";
                }
                {
                  name = "PORT";
                  value = "9101";
                }
                {
                  name = "SCAN_INTERVAL";
                  value = "300";
                }
                {
                  name = "PYTHONUNBUFFERED";
                  value = "1";
                }
              ];
              # Need root to read /var/lib/rancher/k3s/storage on the host.
              securityContext = {
                runAsUser = 0;
                runAsGroup = 0;
                readOnlyRootFilesystem = false;
                capabilities.drop = ["ALL"];
              };
              volumeMounts = [
                {
                  name = "storage";
                  mountPath = "/data/storage";
                  readOnly = true;
                }
                {
                  name = "script";
                  mountPath = "/app";
                  readOnly = true;
                }
              ];
              resources = {
                requests = {
                  cpu = "50m";
                  memory = "64Mi";
                };
                # `du` bursts for a few seconds every five minutes; a CPU
                # quota only throttles that scan and trips CPUThrottlingHigh.
                limits.memory = "256Mi";
              };
              readinessProbe = {
                httpGet = {
                  path = "/metrics";
                  port = 9101;
                };
                initialDelaySeconds = 5;
                periodSeconds = 30;
              };
            }
          ];
          volumes = [
            {
              name = "storage";
              hostPath = {
                path = "/var/lib/rancher/k3s/storage";
                type = "Directory";
              };
            }
            {
              name = "script";
              configMap.name = "local-path-du-exporter";
            }
          ];
        };
      };
    };
  };
}
