# Calendar-month bandwidth tracking for the kwg tunnel — matches the
# Hetzner monthly billing cycle (20 TB out).
#
# How it works:
#  1. Marker rules emit the current counter value ONLY during the first
#     5 minutes of the 1st of each month (UTC). The rest of the time
#     these recordings emit nothing.
#  2. The derived rule = `current counter − last_over_time(marker[31d])`
#     i.e. current value minus whatever the counter was at the most
#     recent month boundary.
#
# Cold-start caveat: on initial deploy (or until the next 1st passes),
# there's no marker in the TSDB → the derived rule emits nothing → the
# Glance widget will be empty. After the first month boundary, it
# populates and stays accurate.
#
# rx side approximates Hetzner's "Traffic out" since the VPS sends those
# bytes through its public NIC to reach engineer through the wg tunnel.
{ ... }:

{
  services.k3s.manifests.wireguard-monthly-rules.content = {
    apiVersion = "monitoring.coreos.com/v1";
    kind       = "PrometheusRule";
    metadata = {
      name      = "wireguard-monthly";
      namespace = "monitoring";
      labels.release = "kube-prometheus-stack";
    };
    spec.groups = [
      {
        name     = "wireguard-monthly";
        interval = "30s";
        rules = [
          {
            record = "wireguard_sent_bytes_at_month_start";
            expr = ''
              wireguard_sent_bytes_total{instance="engineer"}
                and on() (day_of_month() == 1)
                and on() (hour() == 0)
                and on() (minute() < 5)
            '';
          }
          {
            record = "wireguard_received_bytes_at_month_start";
            expr = ''
              wireguard_received_bytes_total{instance="engineer"}
                and on() (day_of_month() == 1)
                and on() (hour() == 0)
                and on() (minute() < 5)
            '';
          }
          {
            record = "wireguard_sent_bytes_since_month_start";
            expr = ''
              wireguard_sent_bytes_total{instance="engineer"}
                - on() last_over_time(wireguard_sent_bytes_at_month_start[31d])
            '';
          }
          {
            record = "wireguard_received_bytes_since_month_start";
            expr = ''
              wireguard_received_bytes_total{instance="engineer"}
                - on() last_over_time(wireguard_received_bytes_at_month_start[31d])
            '';
          }
        ];
      }
    ];
  };
}
