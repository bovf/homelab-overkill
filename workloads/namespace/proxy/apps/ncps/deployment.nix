{...}: let
  ncpsImage = "docker.io/kalbasit/ncps:v0.10.1@sha256:75fe26ea14bc35d336eca877a2e94a768d30631f415198242bbf1e5203f26a47";
in {
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
      # Keep database migrations from overlapping an existing SQLite writer.
      strategy.type = "Recreate";
      selector.matchLabels.app = "ncps";
      template = {
        metadata.labels.app = "ncps";
        spec = {
          initContainers = [
            {
              name = "init-dirs";
              image = "busybox:latest";
              command = ["/bin/sh" "-c"];
              args = ["mkdir -m 0755 -p /storage/var && mkdir -m 0700 -p /storage/var/ncps && mkdir -m 0700 -p /storage/var/ncps/db"];
              volumeMounts = [
                {
                  name = "ncps-data";
                  mountPath = "/storage";
                }
              ];
            }
            {
              name = "init-migrate";
              image = ncpsImage;
              imagePullPolicy = "IfNotPresent";
              command = [
                "/bin/ncps"
                "migrate"
                "up"
                "--cache-database-url=sqlite:/storage/var/ncps/db/db.sqlite"
              ];
              volumeMounts = [
                {
                  name = "ncps-data";
                  mountPath = "/storage";
                }
              ];
            }
          ];
          containers = [
            {
              name = "ncps";
              image = ncpsImage;
              imagePullPolicy = "IfNotPresent";
              command = [
                "/bin/ncps"
                "serve"
                "--cache-hostname=192.168.2.4"
                "--cache-storage-local=/storage"
                "--cache-database-url=sqlite:/storage/var/ncps/db/db.sqlite"
                "--cache-upstream-url=https://cache.nixos.org"
                "--cache-upstream-public-key=cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
              ];
              ports = [
                {
                  containerPort = 8501;
                  name = "http";
                }
              ];
              volumeMounts = [
                {
                  name = "ncps-data";
                  mountPath = "/storage";
                }
              ];
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
            }
          ];
          volumes = [
            {
              name = "ncps-data";
              persistentVolumeClaim.claimName = "ncps-storage";
            }
          ];
        };
      };
    };
  };
}
