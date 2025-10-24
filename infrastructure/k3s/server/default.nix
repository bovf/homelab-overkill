{ lib, pkgs, nodeConfig, ... }:
with lib;
let
  isController = nodeConfig.nodeType == "controller";
  isServer = nodeConfig.role == "server";
in {
  config = mkIf isServer {
    
    services.k3s = {
      enable = true;
      role = "server";
      clusterInit = isController;
      
      extraFlags = [
        "--write-kubeconfig-mode=0644"
        "--tls-san=${nodeConfig.hostname}"
        "--tls-san=${nodeConfig.ip}"
        "--tls-san=${nodeConfig.domain}"
        "--flannel-backend=vxlan"
        "--cluster-cidr=10.42.0.0/16"
        "--service-cidr=10.43.0.0/16"
        "--node-label=node-type=${nodeConfig.nodeType}"
        "--node-label=architecture=${nodeConfig.arch}"
      ];
    };

    networking.firewall.allowedTCPPorts = [ 
      6443  # K3s API server
      80    # HTTP
      443   # HTTPS
    ];
    networking.firewall.allowedUDPPorts = [ 8472 ]; # Flannel
    
    environment.systemPackages = with pkgs; [
      kubectl
      kubernetes-helm
      k9s
    ];
    
    environment.sessionVariables.KUBECONFIG = "/etc/rancher/k3s/k3s.yaml";
    
    workloads.enable = true;
  };
}
