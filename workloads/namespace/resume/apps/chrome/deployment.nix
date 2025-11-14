{ ... }:
{
  services.k3s.manifests.reactive-resume-chrome-deployment = {
    content = {
      apiVersion = "apps/v1";
      kind = "Deployment";
      metadata = {
        name = "chrome";
        namespace = "resume";
        labels = { app = "chrome"; };
      };
      spec = {
        replicas = 1;
        selector = { matchLabels = { app = "chrome"; }; };
        template = {
          metadata = { labels = { app = "chrome"; }; };
          spec = {
            terminationGracePeriodSeconds = 30;
            containers = [
              {
                name = "chrome";
                image = "ghcr.io/browserless/chromium:v2.18.0";
                imagePullPolicy = "IfNotPresent";
                ports = [ { name = "http"; containerPort = 3000; } ];
                env = [
                  { name = "TIMEOUT"; value = "60000"; }
                  { name = "CONCURRENT"; value = "10"; }
                  { 
                    name = "TOKEN"; 
                    valueFrom.secretKeyRef = { 
                      name = "reactive-resume-secrets"; 
                      key = "CHROME_TOKEN"; 
                    }; 
                  }
                  { name = "EXIT_ON_HEALTH_FAILURE"; value = "true"; }
                  { name = "PRE_REQUEST_HEALTH_CHECK"; value = "true"; }
                  
                  # Writable home directory for Corepack/Node
                  { name = "HOME"; value = "/home/blessuser"; }
                  { name = "XDG_CACHE_HOME"; value = "/home/blessuser/.cache"; }
                  { name = "COREPACK_HOME"; value = "/home/blessuser/.cache/node/corepack"; }
                  { name = "COREPACK_ENABLE_DOWNLOAD_PROMPT"; value = "0"; }
                ];
                volumeMounts = [
                  { name = "chrome-home"; mountPath = "/home/blessuser"; }
                  { name = "chrome-tmp"; mountPath = "/tmp"; }
                ];
                readinessProbe = {
                  tcpSocket = { port = 3000; };
                  initialDelaySeconds = 5;
                  periodSeconds = 10;
                  timeoutSeconds = 3;
                  failureThreshold = 3;
                };
                livenessProbe = {
                  tcpSocket = { port = 3000; };
                  initialDelaySeconds = 10;
                  periodSeconds = 20;
                  timeoutSeconds = 5;
                  failureThreshold = 3;
                };
                securityContext = {
                  allowPrivilegeEscalation = false;
                  readOnlyRootFilesystem = true;
                  runAsNonRoot = true;
                  runAsUser = 999;
                  runAsGroup = 999;
                  capabilities = { drop = [ "ALL" ]; };
                };
                resources = {
                  requests = { cpu = "100m"; memory = "512Mi"; };
                  limits = { cpu = "500m"; memory = "2Gi"; };
                };
              }
            ];
            volumes = [
              { name = "chrome-home"; emptyDir = { }; }
              { name = "chrome-tmp"; emptyDir = { }; }
            ];
          };
        };
      };
    };
  };

}
