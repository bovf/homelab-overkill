{ ... }:

{
  imports = [
    ./apps/mumble
  ];

  services.k3s.manifests.mumble-ns.content = {
    apiVersion = "v1";
    kind = "Namespace";
    metadata.name = "mumble";
  };

  networking.firewall.allowedUDPPorts = [ 56472 ];
  networking.firewall.allowedTCPPorts = [ 56472 ];
}
