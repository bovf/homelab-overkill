# Fairwinds Nova — scans installed Helm releases and reports which charts
# have newer versions available upstream. Runs weekly as a CronJob; output
# goes to stdout (captured by Alloy → Loki for searchability).
#
# Ad-hoc run (don't wait for Monday):
#   kubectl -n monitoring create job --from=cronjob/nova nova-manual \
#     && kubectl -n monitoring logs -f job/nova-manual
{ ... }:

{
  imports = [
    ./rbac.nix
    ./cronjob.nix
  ];
}
