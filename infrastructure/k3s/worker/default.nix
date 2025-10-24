# Worker role configuration - applied to ALL workers (future)
{ config, lib, nodeConfig, nodes, ... }:
with lib;
let
  cfg = config.infrastructure.k3s;
  
  # Find controller to join
  controllerNode = lib.findFirst 
    (n: n.nodeType == "controller") 
    null 
    (lib.attrValues nodes);
in {
  config = mkIf (nodeConfig.role == "agent" && cfg.enable) {
    
    services.k3s = {
      enable = true;
      role = "agent";
      serverAddr = mkIf (controllerNode != null)
        "https://${controllerNode.ip}:6443";
      
      extraFlags = [
        "--node-label=node-type=${nodeConfig.nodeType}"
        "--node-label=architecture=${nodeConfig.arch}"
      ];
    };

    networking.firewall.allowedTCPPorts = [ 10250 ];
    networking.firewall.allowedUDPPorts = [ 8472 ];
    
    workloads.enable = mkDefault false;
    
    # Worker optimizations
    boot.kernel.sysctl = {
      "vm.swappiness" = 1;
    };
  };
}
