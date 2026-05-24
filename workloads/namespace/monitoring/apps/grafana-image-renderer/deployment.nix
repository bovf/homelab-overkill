{ ... }:

{
  services.k3s.manifests.grafana-image-renderer-deployment.content = {
    apiVersion = "apps/v1";
    kind = "Deployment";
    metadata = {
      name = "grafana-image-renderer";
      namespace = "monitoring";
      labels."app.kubernetes.io/name" = "grafana-image-renderer";
    };
    spec = {
      replicas = 1;
      selector.matchLabels."app.kubernetes.io/name" = "grafana-image-renderer";
      template = {
        metadata.labels."app.kubernetes.io/name" = "grafana-image-renderer";
        spec = {
          # Renderer ships a headless chromium that doesn't run cleanly as
          # root; the upstream image uses uid 472.
          securityContext = {
            runAsUser  = 472;
            runAsGroup = 472;
            fsGroup    = 472;
          };
          containers = [{
            name  = "renderer";
            image = "docker.io/grafana/grafana-image-renderer:3.12.4";
            ports = [{
              name = "http";
              containerPort = 8081;
              protocol = "TCP";
            }];
            env = [
              { name = "HTTP_HOST";       value = "0.0.0.0"; }
              { name = "HTTP_PORT";       value = "8081"; }
              { name = "ENABLE_METRICS";  value = "true"; }
              { name = "LOG_LEVEL";       value = "info"; }
              { name = "BROWSER_TZ";      value = "Europe/Sofia"; }
              # Sourced from the sops-rendered grafana-image-renderer
              # Secret (secret.nix). Must match GF_RENDERING_RENDERER_TOKEN
              # on Grafana, which uses the same sops placeholder.
              {
                name = "AUTH_TOKEN";
                valueFrom.secretKeyRef = {
                  name = "grafana-image-renderer";
                  key  = "auth-token";
                };
              }
            ];
            securityContext = {
              allowPrivilegeEscalation = false;
              readOnlyRootFilesystem   = false;  # chromium needs /tmp scratch
              capabilities.drop        = [ "ALL" ];
            };
            resources = {
              requests = { cpu = "100m"; memory = "256Mi"; };
              limits   = { cpu = "1000m"; memory = "1Gi"; };
            };
            readinessProbe = {
              httpGet = { path = "/"; port = 8081; };
              initialDelaySeconds = 5;
              periodSeconds       = 30;
            };
            livenessProbe = {
              httpGet = { path = "/"; port = 8081; };
              initialDelaySeconds = 30;
              periodSeconds       = 60;
            };
          }];
        };
      };
    };
  };
}
