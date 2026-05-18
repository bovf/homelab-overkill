# Weekly CronJob that reports Helm releases with newer upstream
# versions. Output goes to stdout → Loki via Alloy.
{ ... }:

{
  imports = [
    ./rbac.nix
    ./cronjob.nix
  ];
}
