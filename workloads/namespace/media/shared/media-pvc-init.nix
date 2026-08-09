{...}: {
  # Job to create required media directories
  services.k3s.manifests.media-directory-init.content = {
    apiVersion = "batch/v1";
    kind = "Job";
    metadata = {
      name = "media-directory-init-v2";
      namespace = "media";
    };
    spec = {
      template = {
        spec = {
          restartPolicy = "OnFailure";
          containers = [
            {
              name = "init";
              image = "busybox:1.38.0";
              command = [
                "sh"
                "-ceu"
                ''
                  dirs="/media /media/complete /media/downloads /media/intermediate /media/movies /media/music /media/nzb /media/queue /media/roms /media/scripts /media/shows /media/sports /media/tmp /media/tv"
                  mkdir -p $dirs
                  chown 1000:1000 $dirs
                  chmod 2775 $dirs
                ''
              ];
              volumeMounts = [
                {
                  name = "media";
                  mountPath = "/media";
                }
              ];
            }
          ];
          volumes = [
            {
              name = "media";
              persistentVolumeClaim.claimName = "media-pvc";
            }
          ];
        };
      };
    };
  };
}
