{ ... }:

{
  # Shared PersistentVolumeClaim for media storage (150Gi)
  services.k3s.manifests.media-pvc.content = {
    apiVersion = "v1";
    kind = "PersistentVolumeClaim";
    metadata = {
      name = "media-pvc";
      namespace = "media";
    };
    spec = {
      accessModes = [ "ReadWriteOnce" ];
      resources = { requests = { storage = "150Gi"; }; };
      storageClassName = "local-path";
    };
  };
}
