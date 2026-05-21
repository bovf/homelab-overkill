{ nodeName, ... }:

# coturn is a raw TCP resource: clients reach turns://turn.dobryops.com:<port>
# over TLS. Only this single port crosses the tunnel — the UDP relay range is
# never exposed, so the zero-exposed-ports model holds. Calls connect via the
# relay<->relay path, bridged internally by coturn.
{
  workloads.pangolinResources.coturn = {
    name           = "Matrix TURN (coturn)";
    protocol       = "tcp";
    proxyPortKey   = "pangolin/resources/coturn/port";
    enabled        = true;
    targetHostname = "coturn.matrix.svc.cluster.local";
    targetPort     = 5349;
    newtInstance   = "engineer-kernel";
    viaKernelWg    = true;
  };

  sops.secrets."pangolin/resources/coturn/port" = {};
  # Consumed by certificate.nix (the cert SAN).
  sops.secrets."pangolin/resources/turn/domain" = {};
}
