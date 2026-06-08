{ ... }:

{
  workloads.pangolinResources.cache = {
    name = "Attic Nix Cache";
    protocol = "http";
    domainKey = "pangolin/resources/cache/domain";
    enabled = true;
    ssoEnabled = false;
    targetHostname = "attic-cache.proxy.svc.cluster.local";
    targetMethod = "http";
    targetPort = 8090;
    newtInstance = "engineer-kernel";
    viaKernelWg = true;
    lanIP = "192.168.2.23";
    healthcheck = {
      hostname = "attic-cache.proxy.svc.cluster.local";
      port = 8090;
      path = "/";
    };
  };

  sops.secrets."pangolin/resources/cache/domain" = {};
}
