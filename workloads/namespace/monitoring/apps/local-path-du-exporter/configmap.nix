{ ... }:

{
  services.k3s.manifests.local-path-du-exporter-config.content = {
    apiVersion = "v1";
    kind = "ConfigMap";
    metadata = {
      name = "local-path-du-exporter";
      namespace = "monitoring";
      labels."app.kubernetes.io/name" = "local-path-du-exporter";
    };
    data."exporter.py" = builtins.readFile ./exporter.py;
  };
}
