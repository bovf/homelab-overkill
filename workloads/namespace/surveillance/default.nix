# Surveillance namespace — currently holds the laptop-webcam streamer.
{ ... }:

{
  imports = [
    ./apps/go2rtc
  ];

  services.k3s.manifests.surveillance-ns.content = {
    apiVersion = "v1";
    kind = "Namespace";
    metadata.name = "surveillance";
  };
}
