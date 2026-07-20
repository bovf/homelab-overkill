{...}: {
  # SSH
  services.openssh = {
    enable = true;
    openFirewall = true;
    startWhenNeeded = false;
    ports = [22];
    settings = {
      UseDns = false;
      PermitRootLogin = "yes";
      KbdInteractiveAuthentication = false;
    };
  };
}
