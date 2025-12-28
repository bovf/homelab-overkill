{ ... }:

{
  # Optional: ConfigMap for NZBGet custom configuration
  services.k3s.manifests.nzbget-config.content = {
    apiVersion = "v1";
    kind = "ConfigMap";
    metadata = {
      name = "nzbget-config";
      namespace = "media";
    };
    data = {
      "nzbget.conf" = ''
        # NZBGet Configuration
        # This is auto-applied on first start
        
        ControlPort=6789
        SecureControl=no
        AllowCookies=yes
        MaxConnectionTime=0
        ConnectionTimeout=60
        TerminateTimeout=120
        ArticleTimeout=60
        KeepHistory=30
        
        # Logging
        LogFile=/config/nzbget.log
        LogLevel=INFO
        
        # Download paths
        MainDir=/downloads
        CompleteDir=/downloads/complete
        InterimDir=/downloads/intermediate
        
        # Server connections
        ArticleCache=0
        ContinuePartial=yes
        CrashTrace=no
        
        # Security
        ControlUsername=nzbget
        ControlPassword=
        AddUserAgent=no
        
        # Category definitions (for integration with Sonarr/Radarr)
        Category1.Name=sonarr
        Category1.DestDir=/downloads/tv
        Category1.Unpack=yes
        
        Category2.Name=radarr
        Category2.DestDir=/downloads/movies
        Category2.Unpack=yes
        
        # Performance
        ServerTimeout=30
        RotateLog=yes
        WriteLogFile=yes
      '';
    };
  };

  # ServiceAccount for NZBGet (if needed for pod security policies)
  services.k3s.manifests.nzbget-serviceaccount.content = {
    apiVersion = "v1";
    kind = "ServiceAccount";
    metadata = {
      name = "nzbget";
      namespace = "media";
    };
  };
}
