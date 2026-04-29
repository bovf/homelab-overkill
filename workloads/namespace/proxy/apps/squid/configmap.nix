{ ... }:

{
  services.k3s.manifests.squid-configmap.content = {
    apiVersion = "v1";
    kind = "ConfigMap";
    metadata = {
      name = "squid-config";
      namespace = "proxy";
    };
    data."squid.conf" = ''
      # Source IP ACLs are ineffective behind k8s pod NAT.
      # Network-level restriction is enforced by the LoadBalancer binding to 192.0.2.10.
      http_access allow all

      http_port 3128
      pid_filename /tmp/squid.pid

      cache_mem 256 MB
      maximum_object_size_in_memory 1 MB
      cache_dir ufs /var/spool/squid 2048 16 256

      access_log stdio:/dev/stdout
      cache_log none
    '';
  };
}
