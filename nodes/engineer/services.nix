{ ... }:

{
  # Point the host (and inherited by CoreDNS via dnsPolicy=Default) at
  # pihole so every cluster pod's external query shows up in pihole's
  # log. 1.1.1.1 is the resolver-of-last-resort if pihole is down.
  networking.nameservers = [ "192.168.2.2" "1.1.1.1" ];

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
