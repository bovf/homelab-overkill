# Engineer node
{ lib, pkgs, ... }:
with lib;
{
  imports = [
    ./hardware.nix
    ./services.nix
    ./disko.nix
  ];
        
  nixpkgs.config = {
    # Allow the specific insecure but required intel-media-sdk
    permittedInsecurePackages = [
      "intel-media-sdk-23.2.2"
    ];
  };

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
      vaapiIntel
      vaapiVdpau
      # Need to see if still needed for gpu-aceleration for media
      # intel-media-sdk
      # libvdpau-va-gl
      # intel-media-driver
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
