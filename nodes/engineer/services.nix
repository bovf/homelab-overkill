{ ... }:

{
  # Tailscale, something is messing with initial nixos-anywhere.
  # services.tailscale = {
  #   enable = true;
  #   openFirewall = true;
  #   useRoutingFeatures = "both";
  #   # TODO Manage it with secret
  #   authKeyFile = "/etc/tailscale/authkey";
  #   extraUpFlags = [
  #     "--advertise-exit-node"
  #     "--acept-route"
  #     "--advertise-routes=192.168.1.0/24"
  #   ];
  # };

  # Virtualization
  virtualisation.containers.enable = true;
  virtualisation = {
    podman = {
      enable = true;
      dockerCompat = false;
      defaultNetwork.settings.dns_enabled = true;
    };
    docker = {
      enable = true;
      daemon.settings = {};
    };
  };
  
  # Add engineer user to docker/podman groups
  users.users.engineer.extraGroups = [ "podman" "docker" ];
}
