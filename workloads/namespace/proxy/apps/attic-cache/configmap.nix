{ ... }:

{
  services.k3s.manifests.attic-cache-config.content = {
    apiVersion = "v1";
    kind = "ConfigMap";
    metadata = {
      name = "attic-cache-config";
      namespace = "proxy";
      labels.app = "attic-cache";
    };
    data."server.toml" = ''
      listen = "0.0.0.0:8080"

      [database]
      url = "sqlite:///var/lib/atticd/server.db?mode=rwc"

      [storage]
      type = "local"
      path = "/var/lib/atticd/storage"

      [chunking]
      nar-size-threshold = 65536
      min-size = 16384
      avg-size = 65536
      max-size = 262144

      [compression]
      type = "zstd"
      level = 8
    '';
  };
}
