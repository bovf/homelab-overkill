{ lib, ... }:
with lib;
{
  imports = [
    ./namespace
  ];

  options.workloads = {
    enable = mkEnableOption "Application workloads";
  };
}
