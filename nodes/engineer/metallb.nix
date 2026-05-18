# Pool sits in 192.168.2.0/24, outside the DHCP range on 192.168.1.0/24.
{ ... }:

{
  services.metallb = {
    enable = true;
    pool = {
      name      = "lan-pool";
      addresses = [ "192.168.2.0/24" ];
    };
  };
}
