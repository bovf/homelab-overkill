{ ... }:

{
  services.pangolin-kwg = {
    enable   = true;
    instance = "engineer-kernel";

    blueprintSync = {
      enable   = true;
      orgId    = "builders-league-united";
      endpoint = "https://api.dobryops.com";
    };

    site = {
      privateKeySopsPath  = "pangolin/instances/engineer-kernel/wg_private_key";
      siteIdSopsPath      = "pangolin/instances/engineer-kernel/site_id";
      peerPublicKey       = "cbD3s/TkYKBqOkfrHCtuHH/247BZNgN8IDhGREjpNAo=";
      endpoint            = "pangolin.dobryops.com:51820";
      address             = [ "100.89.128.16/30" ];
      allowedIPs          = [ "100.89.128.1/32" ];
      listenPort          = 51820;
      persistentKeepalive = 5;
    };

    natRules = {};
  };
}
