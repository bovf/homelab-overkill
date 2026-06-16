{
  config,
  pkgs,
  lib,
  ...
}: {
  # Enable Docker
  virtualisation.docker = {
    enable = true;
    autoPrune = {
      enable = true;
      dates = "weekly";
    };
    extraOptions = "--userland-proxy=false";
  };

  # Enable OCI containers support
  virtualisation.oci-containers.backend = "docker";

  # Add docker and related tools to system packages
  environment.systemPackages = with pkgs; [
    docker
    docker-compose
  ];
}
