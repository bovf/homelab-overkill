{...}: {
  workloads.uptimeMonitors.cache = {
    name = "Attic Nix Cache";
    domainKey = "pangolin/resources/cache/domain";
    group = "Dev";
  };
}
