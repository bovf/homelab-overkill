# Intel iGPU Prometheus exporter (clambin/intel-gpu-exporter).
# Wraps `intel_gpu_top` and exposes utilization/freq/power metrics.
{ ... }:

{
  imports = [
    ./daemonset.nix
    ./service.nix
  ];
}
