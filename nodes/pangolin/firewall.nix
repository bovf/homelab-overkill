{
  config,
  pkgs,
  lib,
  ...
}: {
  networking.firewall = {
    enable = true;
    checkReversePath = false;
    trustedInterfaces = ["docker0"];

    # Open required TCP ports
    allowedTCPPorts = [
      22 # SSH
      80 # HTTP (web)
      443 # HTTPS (websecure)

      1025 # SSH PortSwap
      2222 # GitLab SSH (Pangolin tcp-2222 entry point)
      2223 # Engineer SSH (Pangolin tcp-2223 entry point)
      6443 # k8s API
      6544 # Engineer k8s API (Pangolin tcp-6544 entry point)
      7881 # LiveKit SFU — ICE/TCP media fallback (Element Call)
    ];

    # Open required UDP ports
    allowedUDPPorts = [
      2222 # Gitlab SSH
      50000 # LiveKit SFU — single-port UDP mux (Element Call media)
      51820 # WireGuard VPN
      21820 # Additional WireGuard port
    ];
  };
}
