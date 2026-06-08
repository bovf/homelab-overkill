{ config, pkgs, ... }:

{
  sops.secrets."gitlab/homelab_overkill_runner_token" = {};

  sops.templates."gitlab/homelab-overkill-runner.env" = {
    content = ''
      CI_SERVER_URL=https://${config.sops.placeholder."pangolin/resources/gitlab/domain"}
      CI_SERVER_TOKEN=${config.sops.placeholder."gitlab/homelab_overkill_runner_token"}
    '';
    path = "/run/secrets/gitlab-homelab-overkill-runner.env";
    owner = "root";
    group = "root";
    mode = "0400";
  };

  services.gitlab-runner = {
    enable = true;
    gracefulTermination = true;
    settings = {
      concurrent = 1;
      check_interval = 30;
    };
    extraPackages = with pkgs; [
      attic-client
      bash
      cacert
      coreutils
      git
      nix
      openssh
    ];
    services.homelab-overkill-nix = {
      authenticationTokenConfigFile = "/run/secrets/gitlab-homelab-overkill-runner.env";
      executor = "shell";
      description = "homelab-overkill heavy Nix runner";
      # With GitLab runner-auth-token registration, GitLab owns tags,
      # protected, and run-untagged settings. Create the project runner in the
      # GitLab UI/API with tags:
      # nix,nix-heavy,x86_64-linux,homelab-overkill; protected=true;
      # run_untagged=false.
      limit = 1;
      requestConcurrency = 1;
      environmentVariables = {
        NIX_REMOTE = "daemon";
        NIX_CONFIG = ''
          experimental-features = nix-command flakes
          substituters = https://cache.dobryops.com https://cache.nixos.org
        '';
      };
    };
  };
}
