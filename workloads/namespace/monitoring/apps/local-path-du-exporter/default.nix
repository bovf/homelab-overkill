# Tiny Prometheus exporter for k3s local-path PVC actual disk usage.
# Walks /var/lib/rancher/k3s/storage on the host, runs `du -sb` per PVC dir,
# exposes local_path_pvc_used_bytes{namespace, persistentvolumeclaim, pv}.
{ ... }:

{
  imports = [
    ./configmap.nix
    ./daemonset.nix
    ./service.nix
  ];
}
