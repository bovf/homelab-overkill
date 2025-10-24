{ ... }:
{
  networking = {
    networkmanager.enable = true;
    firewall.allowedTCPPorts = [ 22 ];
  };
}

