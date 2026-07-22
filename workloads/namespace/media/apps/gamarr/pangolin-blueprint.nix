{nodeName, ...}: {
  workloads.pangolinResources.gamarr = {
    name = "Gamarr";
    protocol = "http";
    domainKey = "pangolin/resources/gamarr/domain";
    enabled = true;
    ssoEnabled = true;
    targetHostname = "gamarr.media.svc.cluster.local";
    targetMethod = "http";
    targetPort = 8103;
    newtInstance = "engineer-kernel";
    viaKernelWg = true;
    lanIP = "192.168.2.49";
  };

  sops.secrets."pangolin/resources/gamarr/domain" = {};
}
