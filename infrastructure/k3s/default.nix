{ ... }:

{
  imports = [
    ./cluster.nix
    ./server
    ./worker
    ./networking.nix
  ];

  boot.kernel.sysctl = {
    "net.bridge.bridge-nf-call-iptables" = 1;
    "net.ipv4.ip_forward" = 1;
  };
    
  boot.kernelModules = [ "br_netfilter" ];
    
  systemd.tmpfiles.rules = [
    "d /var/lib/rancher/k3s 0755 root root -"
  ];
}
