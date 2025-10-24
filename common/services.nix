{ ... }:
{
  # SSH
  services.openssh = {
    enable = true;
    openFirewall = true;
    startWhenNeeded = false;
    ports = [ 22 ];
    settings = {
      UseDns = false;
      GSSAPIAuthentication = false;
      PermitRootLogin = "yes";
      KbdInteractiveAuthentication = false;
    };
  };
}
