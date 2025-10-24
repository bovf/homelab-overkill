{ ... }:
{
  services.k3s.manifests.minio-default-public-policy.content = {
    apiVersion = "v1";
    kind = "ConfigMap";
    metadata = {
      name = "minio-default-public-policy";
      namespace = "database";
    };
    data = {
      "policy.json" = builtins.toJSON {
        Version = "2012-10-17";
        Statement = [
          {
            Effect = "Allow";
            Principal = { AWS = [ "*" ]; };
            Action = [ "s3:GetObject" ];
            Resource = [ "arn:aws:s3:::default/*" ];
          }
        ];
      };
    };
  };
}
