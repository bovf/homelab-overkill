# Keel — polls container registries on a schedule and triggers rolling
# updates when a watched tag's digest changes. We use it to auto-deploy
# new builds of internally-hosted apps (e.g. whoami-blog) the moment CI
# republishes :latest, without per-app webhooks.
#
# Per-deployment opt-in via annotations:
#   keel.sh/policy: force
#   keel.sh/trigger: poll
#   keel.sh/pollSchedule: "@every 1m"
{ ... }:

{
  imports = [
    ./helm.nix
  ];
}
