{ config, ... }:

{
  # Keys MUST match Gluetun's documented env var names.
  sops.templates."qbittorrent/qbittorrent-vpn-creds.yaml" = {
    content = ''
      apiVersion: v1
      kind: Secret
      metadata:
        name: qbittorrent-vpn-creds
        namespace: media
      type: Opaque
      stringData:
        VPN_SERVICE_PROVIDER: nordvpn
        VPN_TYPE: wireguard
        WIREGUARD_PRIVATE_KEY: ${config.sops.placeholder."nordvpn/wireguard_private_key"}
        SERVER_COUNTRIES: Bulgaria
    '';
    path  = "/var/lib/rancher/k3s/server/manifests/qbittorrent-vpn-creds.yaml";
    owner = "root";
    group = "root";
    mode  = "0600";
  };
}
