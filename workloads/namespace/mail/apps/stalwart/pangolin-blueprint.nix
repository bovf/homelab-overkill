# Pangolin resources for Stalwart:
#   - 4 raw TCP listeners (SMTP MX, submission STARTTLS, submissions
#     implicit TLS, IMAPS) public on the VPS, tunnelled via kwg to the
#     Service's externalIP on the engineer node.
#   - 1 HTTP resource for the admin UI behind Pangolin SSO.
#
# `viaKernelWg = true` triggers the blueprint sync to rewrite the
# target-hostname to the kwg tunnel IP (100.89.128.16). The cluster-DNS
# names below are informational — they get overridden before the YAML
# is PUT to Pangolin's REST API.
#
# Public ports are pinned literals: MX records can't carry non-standard
# ports, so 25/587/465/993 must match exactly on the VPS side. We don't
# stash them in sops the way gitlab_ssh does — they're public knowledge
# the moment the MX flips.
{ ... }:

{
  workloads.pangolinResources.mail_smtp = {
    name           = "Mail SMTP";
    protocol       = "tcp";
    proxyPort      = 25;
    enabled        = true;
    targetHostname = "stalwart.mail.svc.cluster.local";
    targetPort     = 25;
    newtInstance   = "engineer-kernel";
    viaKernelWg    = true;
  };

  workloads.pangolinResources.mail_submission = {
    name           = "Mail Submission (STARTTLS)";
    protocol       = "tcp";
    proxyPort      = 587;
    enabled        = true;
    targetHostname = "stalwart.mail.svc.cluster.local";
    targetPort     = 587;
    newtInstance   = "engineer-kernel";
    viaKernelWg    = true;
  };

  workloads.pangolinResources.mail_submissions = {
    name           = "Mail Submissions (Implicit TLS)";
    protocol       = "tcp";
    proxyPort      = 465;
    enabled        = true;
    targetHostname = "stalwart.mail.svc.cluster.local";
    targetPort     = 465;
    newtInstance   = "engineer-kernel";
    viaKernelWg    = true;
  };

  workloads.pangolinResources.mail_imaps = {
    name           = "Mail IMAPS";
    protocol       = "tcp";
    proxyPort      = 993;
    enabled        = true;
    targetHostname = "stalwart.mail.svc.cluster.local";
    targetPort     = 993;
    newtInstance   = "engineer-kernel";
    viaKernelWg    = true;
  };

  workloads.pangolinResources.mailadmin = {
    name           = "Mail Admin";
    protocol       = "http";
    domainKey      = "pangolin/resources/mailadmin/domain";
    enabled        = true;
    targetHostname = "stalwart.mail.svc.cluster.local";
    targetMethod   = "http";
    targetPort     = 8083;
    newtInstance   = "engineer-kernel";
    viaKernelWg    = true;
    lanIP          = "192.168.2.70";
  };

  sops.secrets."pangolin/resources/mailadmin/domain" = {};
}
