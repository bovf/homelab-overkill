{ lib, ... }:
with lib;
{
  imports = [
    ./k3s
  ];
  
  options.infrastructure = {
    enable = mkEnableOption "DobryOps infrastructure";
  };
}
