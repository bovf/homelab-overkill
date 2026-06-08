{ ... }:

{
  services.k3s.manifests.attic-cache-pvc.content = {
    apiVersion = "v1";
    kind = "PersistentVolumeClaim";
    metadata = {
      name = "attic-cache-storage";
      namespace = "proxy";
      labels.app = "attic-cache";
    };
    spec = {
      accessModes = [ "ReadWriteOnce" ];
      storageClassName = "local-path";
      resources.requests.storage = "150Gi";
    };
  };
}
