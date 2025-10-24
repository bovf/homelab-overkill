# Core cluster configuration - shared by all nodes
{ ... }:
{
  networking.firewall.extraCommands = ''
    # Allow cluster subnet communication
    iptables -I INPUT -s 10.42.0.0/16 -j ACCEPT
    iptables -I INPUT -s 10.43.0.0/16 -j ACCEPT
    iptables -I INPUT -s 192.168.1.0/24 -j ACCEPT
  '';
}
