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
    ./nix-cache-client.nix
    ./gitlab-runner.nix
    ./audio.nix
    ./wireguard-exporter.nix
    ./uptime.nix
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

  services.hale = {
    enable = true;
    kubeAccess.enable = true;
    agent = {
      enable = true;
      matrix = {
        enable = true;
        authorizedUsersSopsKey   = "hermes/matrix_allowed_users";
        allowedRoomsSopsKey      = "hermes/matrix_allowed_rooms";
        homeChannelChatIdSopsKey = "hermes/matrix_home_channel";
      };
      media.enable = true;
      skills.enable = true;
    };
  };
}
