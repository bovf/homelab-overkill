{...}: {
  workloads.pangolinResources.sparkyfitness = {
    name = "SparkyFitness";
    protocol = "http";
    domainKey = "pangolin/resources/sparkyfitness/domain";
    enabled = true;
    ssoEnabled = false;
    targetHostname = "sparkyfitness.health.svc.cluster.local";
    targetMethod = "http";
    targetPort = 8104;
    newtInstance = "engineer-kernel";
    viaKernelWg = true;
    lanIP = "192.168.2.52";
  };

  sops.secrets."pangolin/resources/sparkyfitness/domain" = {};
}
