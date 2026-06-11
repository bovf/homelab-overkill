{...}: {
  # Helm does not upgrade/install newly-added CRDs on chart upgrade. The
  # 0.36.x operator watches NpuDevicePlugin, but clusters upgraded from
  # 0.32.x do not have that CRD, causing the manager to exit after cache sync
  # timeout. Manage the new CRD explicitly until a fresh install would include
  # it via the chart's crds/ directory.
  services.k3s.manifests.intel-device-plugins-npu-crd.content =
    builtins.fromJSON (builtins.readFile ./npudeviceplugins-crd.json);
}
