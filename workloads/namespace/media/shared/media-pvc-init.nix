{ ... }:

{
  # Job to create required media directories
  services.k3s.manifests.media-directory-init.content = {
    apiVersion = "batch/v1";
    kind = "Job";
    metadata = {
      name = "media-directory-init";
      namespace = "media";
    };
    spec = {
      template = {
        spec = {
          restartPolicy = "OnFailure";
          containers = [
            {
              name = "init";
              image = "busybox:1.36";
              command = [
                "sh"
                "-c"
                ''
                  echo "Creating media directory structure..."
                  mkdir -p /media/movies
                  mkdir -p /media/shows
                  mkdir -p /media/music
                  mkdir -p /media/downloads
                  
                  echo "Setting permissions..."
                  chown -R 1000:1000 /media
                  chmod -R 755 /media
                  
                  echo "Directory structure created successfully!"
                  ls -la /media
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
