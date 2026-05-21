# Matrix namespace — private Synapse homeserver, Element Web client, and
# synapse-admin. VoIP (coturn) runs on the Pangolin VPS, not in-cluster.
{ ... }:

{
  imports = [
    ./apps/synapse
    ./apps/element
    ./apps/synapse-admin
  ];

  services.k3s.manifests.matrix-ns.content = {
    apiVersion = "v1";
    kind = "Namespace";
    metadata.name = "matrix";
  };
}
