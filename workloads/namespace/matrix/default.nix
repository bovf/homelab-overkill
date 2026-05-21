# Matrix namespace — private Synapse homeserver, Element Web client,
# and a coturn TURN server for voice/video calls.
{ ... }:

{
  imports = [
    ./apps/synapse
    ./apps/coturn
    ./apps/element
  ];

  services.k3s.manifests.matrix-ns.content = {
    apiVersion = "v1";
    kind = "Namespace";
    metadata.name = "matrix";
  };
}
