# Sibling Service: the mojo2600 chart's serviceWeb block doesn't
# propagate externalIPs into the rendered Service.
{ ... }:

{
  services.k3s.manifests.pihole-web-extip.content = {
    apiVersion = "v1";
    kind       = "Service";
    metadata = {
      name      = "pihole-web-extip";
      namespace = "dns";
      labels = {
        app                              = "pihole-web-extip";
        "homelab.dobryops.com/extip-for" = "pihole-web";
      };
    };
    spec = {
      type        = "ClusterIP";
      externalIPs = [ "100.89.128.16" ];
      selector = {
        app     = "pihole";
        release = "pihole";
      };
      ports = [
        {
          name       = "http";
          port       = 8089;
          targetPort = 8089;
          protocol   = "TCP";
        }
      ];
    };
  };
}
