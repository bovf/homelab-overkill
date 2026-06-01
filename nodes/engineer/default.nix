# Engineer node
{ lib, pkgs, ... }:
with lib;
{
  imports = [
    ./hardware.nix
    ./services.nix
    ./disko.nix
    ./pangolin-kwg.nix
    ./pangolin-resources.nix
    ./metallb.nix
    ./audio.nix
    ./wireguard-exporter.nix
  ];
        
  # Keyboard US
  services.xserver = {
    xkb = {
      layout = "us";
      variant = "";
    };
  };
  
  # Intel graphics
  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [
      intel-vaapi-driver
      libva-vdpau-driver
      vpl-gpu-rt          # oneVPL GPU runtime for QSV (replaces deprecated intel-media-sdk)
      intel-media-driver  # iHD VA-API driver required for QSV on 6th gen+ Intel CPUs
    ];
  };
  
  # Development tools
  environment.systemPackages = with pkgs; [
    neovim 
    vim 
    git 
    zellij
    btop
  ];

  # Enable workloads and k3s infra
  workloads.enable = true;
  infrastructure.enable = true;
}
