# Mail namespace — Stalwart self-hosted mail server (SMTP MX + IMAPS).
# Outbound is relayed through Brevo to avoid Hetzner IP-reputation issues
# (the Pangolin VPS sits on a flagged subnet for direct port-25 delivery).
{ ... }:

{
  imports = [
    ./apps/stalwart
  ];

  services.k3s.manifests.mail-ns.content = {
    apiVersion = "v1";
    kind = "Namespace";
    metadata.name = "mail";
  };
}
