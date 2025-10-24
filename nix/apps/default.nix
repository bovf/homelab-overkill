{ nixpkgs, nixos-anywhere, ... }:

{
  mkApps = system: enabledNodes:
    let
      secretsModule = import ./secrets.nix { inherit nixpkgs; };
      deployModule  = import ./deploy.nix  { inherit nixpkgs nixos-anywhere; };
      utilities     = import ./utilities.nix { inherit nixpkgs; };
    in {
      secrets = secretsModule.mkSecretsApp system;
      deploy  = deployModule.mkDeployApp system enabledNodes;
      status  = utilities.mkStatusApp system enabledNodes;
    };
}
