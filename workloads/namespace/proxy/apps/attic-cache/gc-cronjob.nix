{ pkgs, ... }:

let
  atticServer = pkgs.attic-server;
in
{
  services.k3s.manifests.attic-cache-gc-cronjob.content = {
    apiVersion = "batch/v1";
    kind = "CronJob";
    metadata = {
      name = "attic-cache-gc";
      namespace = "proxy";
      labels.app = "attic-cache";
    };
    spec = {
      schedule = "17 3 * * *";
      concurrencyPolicy = "Forbid";
      successfulJobsHistoryLimit = 3;
      failedJobsHistoryLimit = 3;
      jobTemplate.spec = {
        backoffLimit = 2;
        template = {
          metadata.labels.app = "attic-cache-gc";
          spec = {
            restartPolicy = "OnFailure";
            containers = [{
              name = "gc";
              image = "busybox:latest";
              imagePullPolicy = "IfNotPresent";
              command = [
                "${atticServer}/bin/atticd"
                "-f"
                "/etc/atticd/server.toml"
                "--mode"
                "garbage-collector-once"
              ];
              envFrom = [{ secretRef.name = "attic-cache-secret"; }];
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
                  cpu = "100m";
                  memory = "256Mi";
                };
                limits = {
                  cpu = "1";
                  memory = "1Gi";
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
  };
}
