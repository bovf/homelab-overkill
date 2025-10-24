{ ... }:

{
  imports = [
    ./apps/postgresql
    ./apps/pgadmin
    ./apps/minio
  ];

  services.k3s.manifests.database-ns.content = {
    apiVersion = "v1";
    kind = "Namespace";
    metadata.name = "database";
  };
}
