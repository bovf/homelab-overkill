{ ... }:

{
  services.k3s.manifests.postgresql-service.content = {
    apiVersion = "v1";
    kind = "Service";
    metadata = {
      name = "postgresql";
      namespace = "database";
      labels.app = "postgresql";
    };
    spec = {
      type = "ClusterIP";
      ports = [{
        port = 5432;
        targetPort = 5432;
        protocol = "TCP";
        name = "postgres";
      }];
      selector.app = "postgresql";
    };
  };
}
