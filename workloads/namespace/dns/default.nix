{ ... }:

{
  imports = [
    ./apps/pihole
  ];

  services.k3s.manifests.dns-ns.content = {
    apiVersion = "v1";
    kind = "Namespace";
    metadata.name = "dns";
  };

  # Pi-hole's LoadBalancer Service binds host port 53 via klipper-lb.
  # Open the firewall so LAN clients can actually reach it.
  networking.firewall.allowedUDPPorts = [ 53 ];
  networking.firewall.allowedTCPPorts = [ 53 ];
}
