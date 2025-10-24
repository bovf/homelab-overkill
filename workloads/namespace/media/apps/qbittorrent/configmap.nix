{ ... }:

{
  # Not Needed: Currently using a config pvc to store configs, might need to configure that to make it more reproducable
  # Custom qBittorrent.conf injected via ConfigMap
  services.k3s.manifests.qbittorrent-config.content = {
    apiVersion = "v1";
    kind = "ConfigMap";
    metadata = {
      name = "qbittorrent-config";
      namespace = "media";
    };
    data = {
      "qBittorrent.conf" = ''
        [AutoRun]
        enabled=false
        program=

        [BitTorrent]
        Session\AddTorrentStopped=false
        Session\DefaultSavePath=/downloads/
        Session\Port=6881
        Session\QueueingSystemEnabled=true
        Session\SSL\Port=41258
        Session\ShareLimitAction=Stop
        Session\TempPath=/downloads/incomplete/

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
        Downloads\TempPath=/downloads/incomplete/
        WebUI\Address=*
        WebUI\ServerDomains=*
        WebUI\HostHeaderValidation=false
        WebUI\CSRFProtection=false
	WebUI\Username=admin
	WebUI\Password_PBKDF2=@ByteArray(42,77,42,236,118,224,68,155,8,247,116,232,234,151,180,240,243,164,240,191,2,242,232,237,225,143,239,67,255,201,17,255,19,3,217,194,172,155,242,184,154,124,3,168,179,62,137,70)
      '';
    };
  };
}
