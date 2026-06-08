{
  lib,
  pkgs,
  ...
}: {
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  time.timeZone = "Europe/Sofia";
  i18n.defaultLocale = "en_US.UTF-8";
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_US.UTF-8";
    LC_IDENTIFICATION = "en_US.UTF-8";
    LC_MEASUREMENT = "en_US.UTF-8";
    LC_MONETARY = "en_US.UTF-8";
    LC_NAME = "en_US.UTF-8";
    LC_NUMERIC = "en_US.UTF-8";
    LC_PAPER = "en_US.UTF-8";
    LC_TELEPHONE = "en_US.UTF-8";
    LC_TIME = "en_US.UTF-8";
  };

  environment.systemPackages = with pkgs; [
    wget
    vim
    jq
    curl
    # terminfo entries so SSH from these terminals doesn't break TUIs
    ghostty.terminfo
    alacritty.terminfo
  ];

  programs.starship = {
    enable = true;
    settings = {
      add_newline = true;
      format = "$username$hostname$directory$git_branch$character";

      username = {
        show_always = false;
        format = "[$user]($style)";
        style_user = "yellow";
        style_root = "bold red";
      };

      hostname = {
        ssh_only = true;
        format = "@[$hostname]($style) ";
        style = "green";
      };

      directory = {
        truncation_length = 3;
        truncate_to_repo = false;
        truncation_symbol = "…/";
        style = "cyan";
      };

      git_branch = {
        symbol = "";
        format = " [$branch]($style) ";
        style = "purple";
      };

      character = {
        success_symbol = "[\\$](bold white)";
        error_symbol = "[\\$](bold red)";
      };
    };
  };

  nixpkgs.config.allowUnfree = true;

  nix = {
    settings = {
      experimental-features = ["nix-command" "flakes"];
      auto-optimise-store = true;
      connect-timeout = 5;
      stalled-download-timeout = 60;
      substituters = lib.mkForce [
        "https://cache.dobryops.com/badwater"
        "https://cache.nixos.org"
      ];
      trusted-public-keys = lib.mkForce [
        "badwater:GfR4TMrcaFJYnsldgBY+P27G620qwd9JRz831f6OxpU="
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      ];
    };
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 30d";
    };
  };

  system.stateVersion = "25.05";
}
