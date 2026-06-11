{...}: {
  workloads.uptimeMonitors.mail = {
    name = "Mail Admin";
    domainKey = "pangolin/resources/mailadmin/domain";
    group = "Comms";
  };

  workloads.uptimeMonitors.mail_smtp = {
    name = "Mail SMTP";
    type = "port";
    host = "stalwart.mail.svc.cluster.local";
    port = 25;
    group = "Comms";
  };

  workloads.uptimeMonitors.mail_submission = {
    name = "Mail Submission";
    type = "port";
    host = "stalwart.mail.svc.cluster.local";
    port = 587;
    group = "Comms";
  };

  workloads.uptimeMonitors.mail_submissions = {
    name = "Mail Submissions TLS";
    type = "port";
    host = "stalwart.mail.svc.cluster.local";
    port = 465;
    group = "Comms";
  };

  workloads.uptimeMonitors.mail_imaps = {
    name = "Mail IMAPS";
    type = "port";
    host = "stalwart.mail.svc.cluster.local";
    port = 993;
    group = "Comms";
  };
}
