# Base system configuration shared by all nodes
{ pkgs, ... }:
{
  # Bootloader
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  
  # Localization (from your current config)
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
  
  # System packages
  environment.systemPackages = with pkgs; [
    wget
    vim
    jq
    curl
    # terminfo entries so SSH'ing in from these terminals doesn't break TUIs
    ghostty.terminfo
    alacritty.terminfo
  ];

  # Minimal Starship prompt — truncates long paths so the prompt stays sane.
  # Single-line, no nerd-font glyphs, works in any terminal.
  programs.starship = {
    enable = true;
    settings = {
      add_newline = true;
      format = "$username$hostname$directory$git_branch$character";

      username = {
        show_always = false;     # hidden for the default user, shown for root / on SSH
        format = "[$user]($style)";
        style_user = "yellow";
        style_root = "bold red";
      };

      hostname = {
        ssh_only = true;          # only show when SSH'd in
        format = "@[$hostname]($style) ";
        style = "green";
      };

      directory = {
        truncation_length = 3;    # last N path components
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
  
  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;
  
  # Nix settings
  nix = {
    settings = {
      experimental-features = [ "nix-command" "flakes" ];
      auto-optimise-store = true;
    };
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 30d";
    };
  };
  
  system.stateVersion = "25.05";
}
