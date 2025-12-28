{ ... }:

{
  sops.templates."mumble/config.yaml" = {
    content = ''
      apiVersion: v1
      kind: Secret
      metadata:
        name: mumble-config
        namespace: mumble
      type: Opaque
      stringData:
        mumble_server_config.ini: |
          welcometext="""
          <a href="https://nixos.org"><img alt="NixOS logo" src="https://nixos.org/logo/nixos-logo-only-hires.png" width="200"></a>
          <a href="https://cachyos.org"><img alt="CachyOS logo" src="https://cachyos.org/logo.png" width="200"></a>

          <h3>Welcome to the Anti‑Discord Free Software Lounge</h3>
          <ul>
            <li><strong>We prefer NixOS, CachyOS and real package managers over closed platforms.</strong></li>
            <li><strong>No telemetry, no dark‑patterns, no corporate lock‑in.</strong></li>
          </ul>

          <hr>
          <h3>Why we don't use Discord / Windows / Big Corps</h3>
          <ul>
            <li>Centralized silos can ban, throttle or mine you at any time.</li>
            <li>Proprietary clients make you depend on someone else's business model.</li>
            <li>Free software gives you reproducibility, control and the option to self‑host.</li>
          </ul>

          <hr>
          <h3>Get involved</h3>
          <ul>
            <li><a href="https://nixos.org">Learn NixOS</a> &mdash; declarative systems, reproducible homelabs.</li>
            <li><a href="https://cachyos.org">Try CachyOS</a> &mdash; Arch‑based, performance‑tuned desktop.</li>
          </ul>

          <hr>
          <h3>House rules</h3>
          <ul>
            <li>The host is not responsible for the content of conversations.</li>
          </ul>
          """

          serverpassword=krisipisi
          users=100
          registerName=BigFuckSmallDiscord
          port=64738
          bandwidth=128000
          logLevel=1
    '';
    path  = "/var/lib/rancher/k3s/server/manifests/mumble-config.yaml";
    owner = "root";
    group = "root";
    mode  = "0644";
  };
}
