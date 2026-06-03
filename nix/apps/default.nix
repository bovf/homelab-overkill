{ nixpkgs, nixos-anywhere, ... }:

{
  mkApps = system: enabledNodes:
    let
      secretsModule    = import ./secrets.nix { inherit nixpkgs; };
      deployModule     = import ./deploy.nix  { inherit nixpkgs nixos-anywhere; };
      utilities        = import ./utilities.nix { inherit nixpkgs; };
      kubeconfigModule = import ./kubeconfig.nix { inherit nixpkgs; };
      scanModule       = import ./scan.nix { inherit nixpkgs; };
    in {
      secrets    = secretsModule.mkSecretsApp system;
      deploy     = deployModule.mkDeployApp system enabledNodes;
      status     = utilities.mkStatusApp system enabledNodes;
      kubeconfig = kubeconfigModule.mkKubeconfigApp system enabledNodes;
      scan       = scanModule.mkScanApp system;
    };
}
