{pkgs, ...}: let
  atticClient = pkgs.attic-client;
  nixUpdate = pkgs.nix-update;

  primeScript = ''
    export HOME=/tmp/attic-home
    mkdir -p "$HOME"

    ${atticClient}/bin/attic login --set-default local http://attic-cache.proxy.svc.cluster.local:8102 "$ATTIC_TOKEN"

    echo "Priming badwater with GitLab Nix runner tool closures"
    ${atticClient}/bin/attic push badwater \
      ${atticClient} \
      ${nixUpdate}
  '';
in {
  services.k3s.manifests.attic-cache-prime-runner-tools-job.content = {
    apiVersion = "batch/v1";
    kind = "Job";
    metadata = {
      name = "attic-cache-prime-runner-tools-v1";
      namespace = "proxy";
      labels.app = "attic-cache";
    };
    spec = {
      backoffLimit = 3;
      template = {
        metadata.labels.app = "attic-cache-prime-runner-tools";
        spec = {
          restartPolicy = "OnFailure";
          containers = [
            {
              name = "prime";
              image = "busybox:latest";
              imagePullPolicy = "IfNotPresent";
              command = ["/bin/sh" "-ec"];
              args = [primeScript];
              envFrom = [{secretRef.name = "attic-cache-secret";}];
              volumeMounts = [
                {
                  name = "nix-store";
                  mountPath = "/nix/store";
                  readOnly = true;
                }
              ];
              resources = {
                requests = {
                  cpu = "100m";
                  memory = "256Mi";
                };
                limits = {
                  cpu = "2";
                  memory = "2Gi";
                };
              };
            }
          ];
          volumes = [
            {
              name = "nix-store";
              hostPath = {
                path = "/nix/store";
                type = "Directory";
              };
            }
          ];
        };
      };
    };
  };

  services.k3s.manifests.attic-cache-prime-runner-tools-cronjob.content = {
    apiVersion = "batch/v1";
    kind = "CronJob";
    metadata = {
      name = "attic-cache-prime-runner-tools";
      namespace = "proxy";
      labels.app = "attic-cache";
    };
    spec = {
      schedule = "43 2 * * 0";
      concurrencyPolicy = "Forbid";
      successfulJobsHistoryLimit = 2;
      failedJobsHistoryLimit = 3;
      jobTemplate.spec = {
        backoffLimit = 3;
        template = {
          metadata.labels.app = "attic-cache-prime-runner-tools";
          spec = {
            restartPolicy = "OnFailure";
            containers = [
              {
                name = "prime";
                image = "busybox:latest";
                imagePullPolicy = "IfNotPresent";
                command = ["/bin/sh" "-ec"];
                args = [primeScript];
                envFrom = [{secretRef.name = "attic-cache-secret";}];
                volumeMounts = [
                  {
                    name = "nix-store";
                    mountPath = "/nix/store";
                    readOnly = true;
                  }
                ];
                resources = {
                  requests = {
                    cpu = "100m";
                    memory = "256Mi";
                  };
                  limits = {
                    cpu = "2";
                    memory = "2Gi";
                  };
                };
              }
            ];
            volumes = [
              {
                name = "nix-store";
                hostPath = {
                  path = "/nix/store";
                  type = "Directory";
                };
              }
            ];
          };
        };
      };
    };
  };
}
