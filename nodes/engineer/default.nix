# Engineer node
{
  lib,
  pkgs,
  ...
}:
with lib; {
  imports = [
    ./hardware.nix
    ./services.nix
    ./disko.nix
    ./pangolin-kwg.nix
    ./pangolin-resources.nix
    ./metallb.nix
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
      vpl-gpu-rt # oneVPL GPU runtime for QSV (replaces deprecated intel-media-sdk)
      intel-media-driver # iHD VA-API driver required for QSV on 6th gen+ Intel CPUs
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

  # Saxton Hale — Matrix-connected media operator with read-only cluster access.
  services.hale = {
    enable = true;
    kubeAccess.enable = true;
    agent = {
      enable = true;
      matrix = {
        enable = true;
        authorizedUsersSopsKey = "hermes/matrix_allowed_users";
        allowedRoomsSopsKey = "hermes/matrix_allowed_rooms";
        homeChannelChatIdSopsKey = "hermes/matrix_home_channel";
      };
      media.enable = true;
      skills.enable = true;
    };
  };

  # Keep the mutable Hermes config intact while enforcing Hale's provider/model.
  systemd.services.hermes-agent = {
    environment.HERMES_HOME = "/home/hale/.hermes";
    serviceConfig = {
      EnvironmentFile = "/home/hale/.hermes/.env";
      ExecStartPre = pkgs.writeShellScript "hale-model-config" ''
        set -eu
        export HOME=/home/hale
        export HERMES_HOME="$HOME/.hermes"
        mkdir -p "$HERMES_HOME"
        ${pkgs.hermes-agent}/bin/hermes config set model.provider openai-codex
        ${pkgs.hermes-agent}/bin/hermes config set model.default gpt-5.6-luna
        ${pkgs.hermes-agent}/bin/hermes config set model.openai_runtime auto
      '';
    };
  };

  # KotH DM is intentionally disabled; keep the module imported so its
  # data/config can be re-enabled later without running the agent now.
  services.koth-dm = {
    enable = false;
    agent = {
      enable = false;
      matrix.enable = false;
      skills.enable = false;
      mcps.enable = false;
    };
  };

  # Third hermes-agent instance — MS research librarian. Independent unix
  # user, mxid, HERMES_HOME, gateway port. See plan-ms-research-agent.md.
  # Sops keys required before rebuild:
  #   hermes/ms_researcher_matrix_password
  #   hermes/ms_researcher_matrix_allowed_users
  #   hermes/ms_researcher_matrix_allowed_rooms
  #   hermes/ms_researcher_matrix_home_channel
  # Disabled after the Codex subscription was cancelled; keep the module and
  # config so the agent can be re-enabled later with a different provider.
  services.ms-researcher = {
    enable = false;
    agent = {
      enable = false;
      matrix.enable = false;
      skills.enable = false;
      cron.enable = false;
      kb = {
        enable = false;
        git = {
          enable = false;
          sync.enable = false;
        };
      };
      mcps.enable = false;
    };
  };
}
