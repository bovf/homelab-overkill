{ ... }:
{
  networking.firewall.extraCommands = ''
    iptables -I INPUT -s 10.42.0.0/16 -j ACCEPT
    iptables -I INPUT -s 10.43.0.0/16 -j ACCEPT
    # /16 covers both the LAN (192.168.1.0/24) and MetalLB pool (192.168.2.0/24).
    iptables -I INPUT -s 192.168.0.0/16 -j ACCEPT
  '';
}
