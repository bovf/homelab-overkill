{config, ...}: {
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
        VPN_SERVICE_PROVIDER: protonvpn
        VPN_TYPE: wireguard
        WIREGUARD_PRIVATE_KEY: ${config.sops.placeholder."protonvpn/wireguard_private_key"}
        SERVER_COUNTRIES: Bulgaria
        VPN_PORT_FORWARDING: "on"
        VPN_PORT_FORWARDING_PROVIDER: protonvpn
        VPN_PORT_FORWARDING_STATUS_FILE: /gluetun/forwarded_port
    '';
    path = "/var/lib/rancher/k3s/server/manifests/qbittorrent-vpn-creds.yaml";
    owner = "root";
    group = "root";
    mode = "0600";
  };
}
