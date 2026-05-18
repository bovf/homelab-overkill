# Sibling Service: the pgadmin4 chart's service block doesn't
# propagate externalIPs into the rendered Service.
{ ... }:

{
  services.k3s.manifests.pgadmin-extip.content = {
    apiVersion = "v1";
    kind       = "Service";
    metadata = {
      name      = "pgadmin-extip";
      namespace = "database";
      labels = {
        app                              = "pgadmin-extip";
        "homelab.dobryops.com/extip-for" = "pgadmin-pgadmin4";
      };
    };
    spec = {
      type        = "ClusterIP";
      externalIPs = [ "100.89.128.16" ];
      selector = {
        "app.kubernetes.io/instance" = "pgadmin";
        "app.kubernetes.io/name"     = "pgadmin4";
      };
      ports = [
        {
          name       = "http";
          port       = 8088;
          targetPort = 80;
          protocol   = "TCP";
        }
      ];
    };
  };
}
