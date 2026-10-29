# Run: nix eval --file nix/apps/check-ncps.nix
let
  module = import ../../workloads/namespace/proxy/apps/ncps/deployment.nix {};
  deployment = module.services.k3s.manifests.ncps-deployment.content.spec;
  pod = deployment.template.spec;
  migration = builtins.head (builtins.filter (c: c.name == "init-migrate") pod.initContainers);
  server = builtins.head (builtins.filter (c: c.name == "ncps") pod.containers);
  databaseFlag = "--cache-database-url=sqlite:/storage/var/ncps/db/db.sqlite";
in
  assert deployment.replicas == 1 && deployment.strategy.type == "Recreate";
  assert migration.image == server.image;
  assert builtins.match "docker.io/kalbasit/ncps:v[0-9.]+@sha256:[0-9a-f]{64}" server.image != null;
  assert migration.imagePullPolicy == "IfNotPresent" && server.imagePullPolicy == "IfNotPresent";
  assert migration.command == ["/bin/ncps" "migrate" "up" databaseFlag];
  assert builtins.elem databaseFlag server.command;
  assert builtins.elem "--cache-storage-local=/storage" server.command;
  assert builtins.elem "--cache-upstream-url=https://cache.nixos.org" server.command;
  assert (builtins.head pod.volumes).persistentVolumeClaim.claimName == "ncps-storage"; "ncps image, migration and SQLite rollout checks passed"
