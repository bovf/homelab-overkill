# Matrix namespace — private Synapse homeserver, Element Web client, and
# synapse-admin. Voice/video is Element Call (LiveKit SFU on the Pangolin VPS).
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
