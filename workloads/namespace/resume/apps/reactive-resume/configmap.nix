{ ... }:

{
  services.k3s.manifests.reactive-resume-config = {
    content = {
      apiVersion = "v1";
      kind = "ConfigMap";
      metadata = {
        name = "reactive-resume-config";
        namespace = "resume";
      };
      data = {
        # App basics
        PORT = "3000";
        NODE_ENV = "production";
        
        # URLs - adjust domain to your setup
        PUBLIC_URL = "https://resume.dobryops.com";
        STORAGE_URL = "https://minio.dobryops.com/reactive-resume-uploads";
        
        # Browserless Chrome WebSocket (internal DNS)
        CHROME_URL = "ws://chrome:3000";
        
        # MinIO configuration (internal service discovery)
        STORAGE_ENDPOINT = "minio.database.svc.cluster.local";
        STORAGE_PORT = "9000";
        STORAGE_REGION = "eu-central-1";
        STORAGE_BUCKET = "reactive-resume-uploads";
        STORAGE_USE_SSL = "false";
        STORAGE_SKIP_BUCKET_CHECK = "false";
      };
    };
  };
}
