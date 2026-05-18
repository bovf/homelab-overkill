{ lib, ... }:
with lib;
{
  imports = [
    ./k3s
    ./metallb
    ./pangolin-kwg
  ];
  
  options.infrastructure = {
    enable = mkEnableOption "DobryOps infrastructure";
  };
}
