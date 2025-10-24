{ config, ... }:

{
  sops = {
    templates = {
      "nordvpn/nordvpn-secret.yaml" = {
        content = ''
          apiVersion: v1
          kind: Secret
          metadata:
            name: nordvpn-secret
            namespace: media
          type: Opaque
          stringData:
            privateKey: "${config.sops.placeholder."nordvpn/wireguard_private_key"}"
            username: "${config.sops.placeholder."nordvpn/username"}"
            password: "${config.sops.placeholder."nordvpn/password"}"
        '';
        path = "/var/lib/rancher/k3s/server/manifests/nordvpn-secret.yaml";
        owner = "root";
        group = "root";
        mode = "0644";
      };
      "qbittorrent/qbittorrent-conf.yaml" = {
        content = ''
          apiVersion: v1
          kind: Secret
          metadata:
            name: qbittorrent-conf
            namespace: media
          type: Opaque
          stringData:
            qbittorrent.conf: |
              [AutoRun]
              enabled=false
              program=
              
              [BitTorrent]
              Session\AddTorrentStopped=false
              Session\DefaultSavePath=/downloads/downloads/
              Session\Port=6881
              Session\QueueingSystemEnabled=true
              Session\SSL\Port=41258
              Session\ShareLimitAction=Stop
              Session\TempPath=/downloads/downloads/incomplete/
              
              [LegalNotice]
              Accepted=true
              
              [Meta]
              MigrationVersion=8
              
              [Network]
              PortForwardingEnabled=false
              Proxy\HostnameLookupEnabled=false
              Proxy\Profiles\BitTorrent=true
              Proxy\Profiles\Misc=true
              Proxy\Profiles\RSS=true
              
              [Preferences]
              Connection\PortRangeMin=6881
              Connection\UPnP=false
              Downloads\SavePath=/downloads/
              Advanced\AnonymousMode=true
              Downloads\TempPath=/downloads/incomplete/
              WebUI\Address=*
              WebUI\ServerDomains=*
              WebUI\HostHeaderValidation=false
              WebUI\CSRFProtection=false
              WebUI\Username=admin
              WebUI\Password_PBKDF2="${config.sops.placeholder."qbittorrent/password_hash"}"
        '';
        path = "/var/lib/rancher/k3s/server/manifests/qbittorrent-conf.yaml";
        owner = "root";
        group = "root";
        mode = "0644";
      };
    };
  };
}
