{nodeName, ...}: {
  workloads.pangolinResources.romm = {
    name = "RomM";
    protocol = "http";
    domainKey = "pangolin/resources/romm/domain";
    enabled = true;
    ssoEnabled = true;
    rules = [
      {
        priority = 1;
        action = "allow";
        match = "country";
        value = "BG";
      }
    ];
    targetHostname = "romm.media.svc.cluster.local";
    targetMethod = "http";
    targetPort = 8105;
    newtInstance = "engineer-kernel";
    viaKernelWg = true;
    lanIP = "192.168.2.53";
  };

  sops.secrets."pangolin/resources/romm/domain" = {};
}
