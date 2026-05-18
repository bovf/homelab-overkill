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
