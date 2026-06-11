{...}: {
  services.k3s.manifests.squid-deployment.content = {
    apiVersion = "apps/v1";
    kind = "Deployment";
    metadata = {
      name = "squid";
      namespace = "proxy";
      labels.app = "squid";
    };
    spec = {
      replicas = 1;
      selector.matchLabels.app = "squid";
      template = {
        metadata.labels.app = "squid";
        spec = {
          securityContext.runAsUser = 13; # proxy user in ubuntu/squid image
          containers = [
            {
              name = "squid";
              image = "ubuntu/squid:6.6-24.04_edge";
              ports = [
                {
                  containerPort = 3128;
                  name = "proxy";
                }
              ];
              volumeMounts = [
                {
                  name = "squid-config";
                  mountPath = "/etc/squid/squid.conf";
                  subPath = "squid.conf";
                }
              ];
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
            {
              name = "squid-config";
              configMap.name = "squid-config";
            }
          ];
        };
      };
    };
  };
}
