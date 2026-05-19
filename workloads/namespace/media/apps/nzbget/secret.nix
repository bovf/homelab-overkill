{ config, ... }:

{
  # The initContainer in helm.nix copies this into the /config PVC on
  # every pod start so the in-container config stays declarative.
  sops.templates."nzbget/nzbget-conf.yaml" = {
    content = ''
      apiVersion: v1
      kind: Secret
      metadata:
        name: nzbget-conf
        namespace: media
      type: Opaque
      stringData:
        nzbget.conf: |
          ControlPort=6789
          ControlUsername=${config.sops.placeholder."media/nzbget/username"}
          ControlPassword=${config.sops.placeholder."media/nzbget/password"}
          SecureControl=no
          FormAuth=yes
          WebDir=/app/nzbget/webui
          ConfigTemplate=/app/nzbget/share/nzbget/nzbget.conf

          MainDir=/downloads
          DestDir=/downloads/complete
          InterDir=/downloads/intermediate
          TempDir=/downloads/tmp
          NzbDir=/downloads/nzb
          QueueDir=/downloads/queue
          ScriptDir=/downloads/scripts
          LogFile=/config/nzbget.log

          Category1.Name=sonarr
          Category1.DestDir=/downloads/tv
          Category1.Unpack=yes

          Category2.Name=radarr
          Category2.DestDir=/downloads/movies
          Category2.Unpack=yes

          Unpack=yes
          UnpackCleanupDisk=yes

          WriteLog=rotate
          RotateLog=3
          LogBufferSize=1000
          DetailTarget=log
          InfoTarget=log
          WarningTarget=log
          ErrorTarget=log
          DebugTarget=log

          ArticleCache=500
          WriteBuffer=1024
          DirectWrite=yes
          ContinuePartial=yes
          ReorderFiles=yes
          PostStrategy=balanced
          DiskSpace=250

          ConnectionTimeout=60
          ArticleTimeout=60
          KeepHistory=30

          AuthorizedIP=127.0.0.1

          Server1.Active=yes
          Server1.Name=Easy News
          Server1.Level=0
          Server1.Optional=no
          Server1.Group=0
          Server1.Host=${config.sops.placeholder."media/nzbget/news_server/host"}
          Server1.Port=563
          Server1.Username=${config.sops.placeholder."media/nzbget/news_server/username"}
          Server1.Password=${config.sops.placeholder."media/nzbget/news_server/password"}
          Server1.JoinGroup=no
          Server1.Encryption=yes
          Server1.Cipher=
          Server1.Connections=30
          Server1.Retention=0
          Server1.IpVersion=auto
          Server1.Notes=
    '';
    path  = "/var/lib/rancher/k3s/server/manifests/nzbget-conf.yaml";
    owner = "root";
    group = "root";
    mode  = "0644";
  };

  services.k3s.manifests.nzbget-serviceaccount.content = {
    apiVersion = "v1";
    kind       = "ServiceAccount";
    metadata = {
      name      = "nzbget";
      namespace = "media";
    };
  };
}
