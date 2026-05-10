{ nodeName, ... }:

{
  workloads.pangolinResources.whoami = {
    name           = "whoami blog";
    protocol       = "http";
    domainKey      = "pangolin/resources/whoami/domain";
    enabled        = true;
    # Public personal blog — no SSO in front of it.
    ssoEnabled     = false;
    targetHostname = "traefik.kube-system.svc.cluster.local";
    targetMethod   = "https";
    targetPort     = 443;
    newtInstance   = nodeName;
    # Pangolin's healthcheck can't set a Host header, so it bypasses Traefik
    # routing — point it at the nginx Service directly. `/` returns the
    # index page (200 OK) for any healthy build of the blog.
    healthcheck = {
      hostname = "whoami.blog.svc.cluster.local";
      port     = 80;
      path     = "/";
    };
  };

  sops.secrets."pangolin/resources/whoami/domain" = {};
}
