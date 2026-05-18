# Without --disable=servicelb, klipper-lb and MetalLB fight for the
# same Services.
{ config, lib, ... }:
with lib;
let
  cfg = config.services.metallb;
in {
  config = mkIf cfg.enable {
    services.k3s.extraFlags = mkAfter [ "--disable=servicelb" ];
  };
}
