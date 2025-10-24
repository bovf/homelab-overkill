{ ... }:
{
  services.k3s.manifests.reactive-resume-minio-policy = {
    content = {
      apiVersion = "v1";
      kind = "ConfigMap";
      metadata = {
        name = "reactive-resume-minio-policy";
        namespace = "database";
      };
      data = {
        "policy.json" = builtins.toJSON {
          Version = "2012-10-17";
          Statement = [
            {
              Effect = "Allow";
              Action = [
                "s3:GetObject"
                "s3:PutObject"
                "s3:DeleteObject"
                "s3:ListBucket"
              ];
              Resource = [
                "arn:aws:s3:::reactive-resume-uploads"
                "arn:aws:s3:::reactive-resume-uploads/*"
                "arn:aws:s3:::reactive-resume-resumes"
                "arn:aws:s3:::reactive-resume-resumes/*"
              ];
            }
          ];
        };
      };
    };
  };
}
