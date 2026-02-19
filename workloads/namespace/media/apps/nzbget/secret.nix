{ config, ... }:

{
  # Render the full nzbget.conf as a Kubernetes Secret.
  # k3s auto-applies it from server/manifests before the pod starts.
  # The initContainer in helm.nix copies it into the /config PVC so NZBGet
  # picks it up on every (re)start, making configuration fully declarative.
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
          # ---------------------------------------------------------------
          # NZBGet declarative configuration — managed by sops-nix
          # Do not edit inside the container; changes will be overwritten.
          # ---------------------------------------------------------------

          # Web UI
          ControlPort=6789
          ControlUsername=${config.sops.placeholder."media/nzbget/username"}
          ControlPassword=${config.sops.placeholder."media/nzbget/password"}
          SecureControl=no
          FormAuth=yes
          WebDir=/app/nzbget/webui
          ConfigTemplate=/app/nzbget/share/nzbget/nzbget.conf

          # Paths — all explicit to avoid resolving relative to $HOME
          MainDir=/downloads
          DestDir=/downloads/complete
          InterDir=/downloads/intermediate
          TempDir=/downloads/tmp
          NzbDir=/downloads/nzb
          QueueDir=/downloads/queue
          ScriptDir=/downloads/scripts
          LogFile=/config/nzbget.log

          # Download categories — used by Sonarr / Radarr
          Category1.Name=sonarr
          Category1.DestDir=/downloads/tv
          Category1.Unpack=yes

          Category2.Name=radarr
          Category2.DestDir=/downloads/movies
          Category2.Unpack=yes

          # Unpack
          Unpack=yes
          UnpackCleanupDisk=yes

          # Logging (WriteLog valid values: none/append/reset/rotate)
          WriteLog=rotate
          RotateLog=3
          LogBufferSize=1000
          DetailTarget=log
          InfoTarget=log
          WarningTarget=log
          ErrorTarget=log
          DebugTarget=log

          # Performance
          ArticleCache=500
          WriteBuffer=1024
          DirectWrite=yes
          ContinuePartial=yes
          ReorderFiles=yes
          PostStrategy=balanced
          DiskSpace=250

          # Connection
          ConnectionTimeout=60
          ArticleTimeout=60
          KeepHistory=30

          # Security
          AuthorizedIP=127.0.0.1
    '';
    path  = "/var/lib/rancher/k3s/server/manifests/nzbget-conf.yaml";
    owner = "root";
    group = "root";
    mode  = "0644";
  };

  # ServiceAccount for NZBGet (kept here after configmap.nix removal)
  services.k3s.manifests.nzbget-serviceaccount.content = {
    apiVersion = "v1";
    kind       = "ServiceAccount";
    metadata = {
      name      = "nzbget";
      namespace = "media";
    };
  };
}
