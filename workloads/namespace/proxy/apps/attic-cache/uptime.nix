{...}: {
  workloads.uptimeMonitors.cache = {
    name = "Attic Nix Cache";
    domainKey = "pangolin/resources/cache/domain";
    path = "/badwater/nix-cache-info";
    group = "Dev";
  };
}
