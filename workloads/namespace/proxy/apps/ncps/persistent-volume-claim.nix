{ ... }:

{
  services.k3s.manifests.ncps-pvc.content = {
    apiVersion = "v1";
    kind = "PersistentVolumeClaim";
    metadata = {
      name = "ncps-storage";
      namespace = "proxy";
    };
    spec = {
      accessModes = [ "ReadWriteOnce" ];
      storageClassName = "local-path";
      resources.requests.storage = "20Gi";
    };
  };
}
