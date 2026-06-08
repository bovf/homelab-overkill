{ pkgs, ... }:

let
  atticServer = pkgs.attic-server;
in
{
  services.k3s.manifests.attic-cache-deployment.content = {
    apiVersion = "apps/v1";
    kind = "Deployment";
    metadata = {
      name = "attic-cache";
      namespace = "proxy";
      labels.app = "attic-cache";
    };
    spec = {
      replicas = 1;
      strategy.type = "Recreate";
      selector.matchLabels.app = "attic-cache";
      template = {
        metadata = {
          labels.app = "attic-cache";
          annotations = {
            "configmap.reloader.stakater.com/reload" = "attic-cache-config";
            "secret.reloader.stakater.com/reload" = "attic-cache-secret";
          };
        };
        spec = {
          initContainers = [{
            name = "init-attic-dirs";
            image = "busybox:latest";
            command = [ "/bin/sh" "-c" ];
            args = [ "mkdir -m 0700 -p /var/lib/atticd/storage && touch /var/lib/atticd/server.db && chmod 0600 /var/lib/atticd/server.db" ];
            volumeMounts = [{
              name = "attic-data";
              mountPath = "/var/lib/atticd";
            }];
          }];
          containers = [{
            name = "attic-cache";
            image = "busybox:latest";
            imagePullPolicy = "IfNotPresent";
            command = [
              "${atticServer}/bin/atticd"
              "-f"
              "/etc/atticd/server.toml"
              "--mode"
              "monolithic"
            ];
            envFrom = [{ secretRef.name = "attic-cache-secret"; }];
            ports = [{
              name = "http";
              containerPort = 8080;
              protocol = "TCP";
            }];
            readinessProbe = {
              tcpSocket.port = "http";
              initialDelaySeconds = 5;
              periodSeconds = 10;
            };
            livenessProbe = {
              tcpSocket.port = "http";
              initialDelaySeconds = 30;
              periodSeconds = 30;
            };
            volumeMounts = [
              {
                name = "nix-store";
                mountPath = "/nix/store";
                readOnly = true;
              }
              {
                name = "attic-config";
                mountPath = "/etc/atticd";
                readOnly = true;
              }
              {
                name = "attic-data";
                mountPath = "/var/lib/atticd";
              }
            ];
            resources = {
              requests = {
                cpu = "250m";
                memory = "512Mi";
              };
              limits = {
                cpu = "2";
                memory = "2Gi";
              };
            };
          }];
          volumes = [
            {
              name = "nix-store";
              hostPath = {
                path = "/nix/store";
                type = "Directory";
              };
            }
            {
              name = "attic-config";
              configMap.name = "attic-cache-config";
            }
            {
              name = "attic-data";
              persistentVolumeClaim.claimName = "attic-cache-storage";
            }
          ];
        };
      };
    };
  };
}
