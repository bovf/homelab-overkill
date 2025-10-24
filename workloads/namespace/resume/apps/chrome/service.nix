{ ... }:

{
  # Chrome service
  services.k3s.manifests.reactive-resume-chrome-service = {
    content = {
      apiVersion = "v1";
      kind = "Service";
      metadata = {
        name = "chrome";
        namespace = "resume";
        labels = { app = "chrome"; };
      };
      spec = {
        selector = { app = "chrome"; };
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
