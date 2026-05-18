# Sibling Services: the gitlab chart's webservice/registry sub-blocks
# don't propagate externalIPs into the rendered Services.
{ ... }:

{
  services.k3s.manifests.gitlab-webservice-extip.content = {
    apiVersion = "v1";
    kind       = "Service";
    metadata = {
      name      = "gitlab-webservice-extip";
      namespace = "cicd";
      labels = {
        app                              = "gitlab-webservice-extip";
        "homelab.dobryops.com/extip-for" = "gitlab-webservice-default";
      };
    };
    spec = {
      type        = "ClusterIP";
      externalIPs = [ "100.89.128.16" ];
      selector = {
        app                          = "webservice";
        release                      = "gitlab";
        "gitlab.com/webservice-name" = "default";
      };
      ports = [
        {
          name       = "http";
          port       = 8181;
          targetPort = 8181;
          protocol   = "TCP";
        }
      ];
    };
  };

  services.k3s.manifests.gitlab-registry-extip.content = {
    apiVersion = "v1";
    kind       = "Service";
    metadata = {
      name      = "gitlab-registry-extip";
      namespace = "cicd";
      labels = {
        app                              = "gitlab-registry-extip";
        "homelab.dobryops.com/extip-for" = "gitlab-registry";
      };
    };
    spec = {
      type        = "ClusterIP";
      externalIPs = [ "100.89.128.16" ];
      selector = {
        app     = "registry";
        release = "gitlab";
      };
      ports = [
        {
          name       = "http";
          port       = 5000;
          targetPort = 5000;
          protocol   = "TCP";
        }
      ];
    };
  };

  # Tunnel-side ingress for git-over-SSH on an internal-only port (the
  # user-facing port stays in sops; this one only ever appears inside
  # the WG tunnel).
  services.k3s.manifests.gitlab-shell-extip.content = {
    apiVersion = "v1";
    kind       = "Service";
    metadata = {
      name      = "gitlab-shell-extip";
      namespace = "cicd";
      labels = {
        app                              = "gitlab-shell-extip";
        "homelab.dobryops.com/extip-for" = "gitlab-gitlab-shell";
      };
    };
    spec = {
      type        = "ClusterIP";
      externalIPs = [ "100.89.128.16" ];
      selector = {
        app     = "gitlab-shell";
        release = "gitlab";
      };
      ports = [
        {
          name       = "ssh";
          port       = 22022;
          targetPort = 2222;
          protocol   = "TCP";
        }
      ];
    };
  };
}
