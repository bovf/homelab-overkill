{ ... }:

{
  services.k3s.manifests.reactive-resume-service = {
    content = {
      apiVersion = "v1";
      kind = "Service";
      metadata = {
        name = "reactive-resume";
        namespace = "resume";
        labels = { app = "reactive-resume"; };
      };
      spec = {
        selector = { app = "reactive-resume"; };
        ports = [
          {
            name = "http";
            port = 3000;
            targetPort = 3000;
            protocol = "TCP";
          }
        ];
        type = "ClusterIP";
      };
    };
  };
}
