{ ... }:

{
  services.k3s.manifests.ncps-deployment.content = {
    apiVersion = "apps/v1";
    kind = "Deployment";
    metadata = {
      name = "ncps";
      namespace = "proxy";
      labels.app = "ncps";
    };
    spec = {
      replicas = 1;
      selector.matchLabels.app = "ncps";
      template = {
        metadata.labels.app = "ncps";
        spec = {
          initContainers = [
            {
              name = "init-dirs";
              image = "busybox:latest";
              command = [ "/bin/sh" "-c" ];
              args = [ "mkdir -m 0755 -p /storage/var && mkdir -m 0700 -p /storage/var/ncps && mkdir -m 0700 -p /storage/var/ncps/db" ];
              volumeMounts = [{
                name = "ncps-data";
                mountPath = "/storage";
              }];
            }
            {
              name = "init-migrate";
              image = "kalbasit/ncps:latest";
              command = [
                "/bin/dbmate"
                "--url=sqlite:/storage/var/ncps/db/db.sqlite"
                "migrate"
                "up"
              ];
              volumeMounts = [{
                name = "ncps-data";
                mountPath = "/storage";
              }];
            }
          ];
          containers = [{
            name = "ncps";
            image = "kalbasit/ncps:latest";
            command = [
              "/bin/ncps"
              "serve"
              "--cache-hostname=192.168.2.4"
              "--cache-data-path=/storage"
              "--cache-database-url=sqlite:/storage/var/ncps/db/db.sqlite"
              "--upstream-cache=https://cache.nixos.org"
              "--upstream-public-key=cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
            ];
            ports = [{
              containerPort = 8501;
              name = "http";
            }];
            volumeMounts = [{
              name = "ncps-data";
              mountPath = "/storage";
            }];
            resources = {
              requests = {
                cpu = "100m";
                memory = "128Mi";
              };
              limits = {
                cpu = "500m";
                memory = "512Mi";
              };
            };
          }];
          volumes = [{
            name = "ncps-data";
            persistentVolumeClaim.claimName = "ncps-storage";
          }];
        };
      };
    };
  };
}
