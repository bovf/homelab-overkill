{...}: {
  # Keep in-cluster lookups for dobryops.com aligned with Pi-hole's
  # split-horizon LAN records while preserving deployability when Pi-hole is
  # unavailable. CoreDNS tries Pi-hole first, then falls back to public DNS.
  services.k3s.manifests.coredns-custom.content = {
    apiVersion = "v1";
    kind = "ConfigMap";
    metadata = {
      name = "coredns-custom";
      namespace = "kube-system";
      labels.app = "coredns";
    };
    data."dobryops.server" = ''
      dobryops.com:53 {
          errors
          cache 30
          forward . 192.168.2.2 1.1.1.1 8.8.8.8 {
              policy sequential
              health_check 5s
              max_fails 2
          }
      }
    '';
  };
}
