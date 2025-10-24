{ ... }:

{
  # Reactive Resume deployment
  services.k3s.manifests.reactive-resume-deployment = {
    content = {
      apiVersion = "apps/v1";
      kind = "Deployment";
      metadata = {
        name = "reactive-resume";
        namespace = "resume";
        labels = { app = "reactive-resume"; };
      };
      spec = {
        replicas = 1;
        selector = { matchLabels = { app = "reactive-resume"; }; };
        template = {
          metadata = { labels = { app = "reactive-resume"; }; };
          spec = {
            terminationGracePeriodSeconds = 90;
            containers = [
              {
                name = "app";
                image = "amruthpillai/reactive-resume:v4.4.6";
                imagePullPolicy = "IfNotPresent";
                ports = [ { name = "http"; containerPort = 3000; } ];
                
                # Load both config and secrets
                envFrom = [
                  { configMapRef = { name = "reactive-resume-config"; }; }
                  { secretRef = { name = "reactive-resume-secrets"; }; }
                ];
                
                # Additional environment variables
                env = [
                  { name = "HOME"; value = "/home/node"; }
                  { name = "HOST"; value = "0.0.0.0"; }
                  { name = "XDG_CACHE_HOME"; value = "/home/node/.cache"; }
                  { name = "COREPACK_HOME"; value = "/home/node/.cache/node/corepack"; }
                ];
                
                volumeMounts = [
                  { name = "app-home"; mountPath = "/home/node"; }
                  { name = "app-tmp"; mountPath = "/tmp"; }
                ];
                
                # Readiness probe - app is ready to accept traffic
                readinessProbe = {
                  httpGet = {
                    path = "/api/health";
                    port = 3000;
                    scheme = "HTTP";
                  };
                  initialDelaySeconds = 30;
                  periodSeconds = 10;
                  timeoutSeconds = 5;
                  failureThreshold = 6;
                };
                
                # Liveness probe - restart if unhealthy
                livenessProbe = {
                  httpGet = {
                    path = "/api/health";
                    port = 3000;
                    scheme = "HTTP";
                  };
                  initialDelaySeconds = 60;
                  periodSeconds = 20;
                  timeoutSeconds = 15;
                  failureThreshold = 3;
                };
                
                # Startup probe - wait for startup
                startupProbe = {
                  httpGet = {
                    path = "/api/health";
                    port = 3000;
                    scheme = "HTTP";
                  };
                  periodSeconds = 15;
                  timeoutSeconds = 10;
                  failureThreshold = 30;
                };
                
                securityContext = {
                  allowPrivilegeEscalation = false;
                  readOnlyRootFilesystem = true;
                  runAsNonRoot = true;
                  runAsUser = 10001;
                  runAsGroup = 10001;
                  capabilities = { drop = [ "ALL" ]; };
                };
                
                resources = {
                  requests = {
                    cpu = "100m";
                    memory = "256Mi";
                  };
                  limits = {
                    cpu = "500m";
                    memory = "512Mi";
                  };
                };
              }
            ];
            
            volumes = [
              { name = "app-home"; emptyDir = { }; }
              { name = "app-tmp"; emptyDir = { }; }
            ];
          };
        };
      };
    };
  };
}
