{ ... }:

{
  workloads.pangolinResources.ms_researcher_kb = {
    name           = "MS Researcher KB";
    protocol       = "http";
    domainKey      = "pangolin/resources/ms_kb/domain";
    enabled        = true;
    ssoEnabled     = true;
    targetHostname = "ms-researcher-kb.knowledgebase.svc.cluster.local";
    targetMethod   = "http";
    targetPort     = 8101;
    newtInstance   = "engineer-kernel";
    viaKernelWg    = true;
    lanIP          = "192.168.2.77";
  };

  sops.secrets."pangolin/resources/ms_kb/domain" = {};
}
