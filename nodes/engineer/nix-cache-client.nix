{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    attic-client
  ];

  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    substituters = [
      "https://cache.dobryops.com"
      "https://cache.nixos.org"
    ];
    trusted-public-keys = [
      # Temporary valid-shaped placeholder. Replace with the public key printed
      # by `attic cache info badwater` after the bootstrap Job creates the cache.
      "badwater:AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA="
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
    ];
    trusted-users = [
      "root"
      "@wheel"
      "gitlab-runner"
    ];
    max-jobs = 1;
    cores = 8;
  };
}
