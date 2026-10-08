# Run: nix eval --offline --impure --file nix/apps/check-heavy-ssh.nix
let
  flake = builtins.getFlake (toString ../..);
  inherit (flake.inputs.nixpkgs) lib;
  engineer = flake.nixosConfigurations.engineer.config;
  pangolin = flake.nixosConfigurations.pangolin.config;
  resource = engineer.workloads.pangolinResources.heavy_ssh;
  forward = engineer.services.pangolin-kwg.natRules.heavy_ssh;
  blueprint = engineer.sops.templates."pangolin-kwg/blueprint.yaml".content;
  firewall = engineer.networking.firewall;
  secret = "pangolin/resources/heavy_ssh/port";
  # sops-nix requires decrypted string leaves; numeric ciphertext also looks like a string.
  encryptedPortLine =
    lib.head (lib.splitString "\n" (lib.last
        (lib.splitString "heavy_ssh:\n" (builtins.readFile engineer.sops.secrets.${secret}.sopsFile))));
  encryptedPortIsString =
    lib.hasInfix "port: ENC[AES256_GCM," encryptedPortLine
    && lib.hasSuffix ",type:str]" encryptedPortLine;
  dnat = "-i pangolin-kwg -p tcp --dport 2224 -j DNAT --to-destination 192.168.1.5:22";
  snat = "-s 100.89.128.0/24 ! -o pangolin-kwg -j MASQUERADE";
in
  assert builtins.elem "setupSecrets" engineer.system.activationScripts.pangolin-kwg-blueprint-resync.deps;
  assert !resource.enabled && resource.viaKernelWg && resource.protocol == "tcp";
  assert resource.newtInstance == "engineer-kernel";
  assert resource.targetHostname == "100.89.128.16";
  assert resource.targetPort == 2224 && forward.listenPort == resource.targetPort;
  assert forward.protocol == "tcp" && forward.target == "192.168.1.5:22";
  assert resource.proxyPortKey == secret && resource.proxyPort == null;
  assert builtins.hasAttr secret engineer.sops.secrets;
  assert lib.asserts.assertMsg encryptedPortIsString "Heavy SSH port must be a SOPS string (\"2224\"), not a number";
  assert lib.hasInfix "heavy_ssh:" blueprint;
  assert lib.hasInfix "proxy-port: ${engineer.sops.placeholder.${secret}}" blueprint;
  assert lib.hasInfix "hostname: 100.89.128.16\n            port: 2224" blueprint;
  assert lib.hasInfix "iptables -t nat -A PREROUTING ${dnat}" firewall.extraCommands;
  assert lib.hasInfix "iptables -t nat -D PREROUTING ${dnat}" firewall.extraStopCommands;
  assert lib.hasInfix "iptables -t nat -A POSTROUTING ${snat}" firewall.extraCommands;
  assert lib.hasInfix "iptables -t nat -D POSTROUTING ${snat}" firewall.extraStopCommands;
  assert pangolin.services.traefik.staticConfigOptions.entryPoints.tcp-2224.address == ":2224/tcp";
  assert builtins.elem 2224 pangolin.networking.firewall.allowedTCPPorts;
  assert !(builtins.elem 2224 pangolin.networking.firewall.allowedUDPPorts);
  assert !engineer.workloads.pangolinResources.engineer_ssh.enabled;
  assert engineer.workloads.pangolinResources.engineer_ssh.targetPort == 22;
  assert engineer.workloads.pangolinResources.engineer_k8s_api.targetPort == 6443;
  assert pangolin.services.traefik.staticConfigOptions.entryPoints.tcp-2223.address == ":2223/tcp";
  assert builtins.elem 2223 pangolin.networking.firewall.allowedTCPPorts; "Heavy SSH configuration checks passed"
