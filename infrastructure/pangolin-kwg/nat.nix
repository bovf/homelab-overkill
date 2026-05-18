# DNAT + supporting rules for decrypted WG ingress.
# Uses iptables (not nftables) to stay compatible with the existing
# extraCommands rules in infrastructure/k3s/cluster.nix.
{ config, lib, ... }:
with lib;
let
  cfg = config.services.pangolin-kwg;

  iface = cfg.interfaceName;

  mkDnatRule = _name: r:
    "iptables -t nat -A PREROUTING -i ${iface} -p ${r.protocol} --dport ${toString r.listenPort} -j DNAT --to-destination ${r.target}";

  dnatRules = concatStringsSep "\n      " (mapAttrsToList mkDnatRule cfg.natRules);
  hasDnat   = cfg.natRules != {};

  tunnelCidr = "100.89.128.0/24";

  natBlock = optionalString hasDnat ''
        ${dnatRules}
        iptables -t nat -A POSTROUTING -s ${tunnelCidr} ! -o ${iface} -j MASQUERADE
  '';

  # MSS clamp every SYN that crosses the tunnel. FORWARD covers cluster
  # traffic (kube-proxy DNAT → pods); OUTPUT covers locally-generated
  # replies (engineer sshd, k3s API). TCPMSS is not valid in mangle
  # INPUT — the kernel uses its OUTPUT path for reply MSS anyway, so
  # clamping there is enough. gerbil pins tunnel MTU at 1280 and PMTU-D
  # is blackholed.
  mssClamp = ''
        iptables -t mangle -A FORWARD -i ${iface} -p tcp --tcp-flags SYN,RST SYN -j TCPMSS --clamp-mss-to-pmtu
        iptables -t mangle -A FORWARD -o ${iface} -p tcp --tcp-flags SYN,RST SYN -j TCPMSS --clamp-mss-to-pmtu
        iptables -t mangle -A OUTPUT  -o ${iface} -p tcp --tcp-flags SYN,RST SYN -j TCPMSS --clamp-mss-to-pmtu
  '';
in {
  config = mkIf cfg.enable {
    networking.firewall.extraCommands = ''
      ${natBlock}
      iptables -A FORWARD -i ${iface} -j ACCEPT
      iptables -A FORWARD -o ${iface} -j ACCEPT
      ${mssClamp}
    '';

    # Mirror in extraStopCommands so a reload (which calls stop+start)
    # doesn't accumulate duplicate rules. Ignore errors on missing rules
    # (first boot, partial state).
    networking.firewall.extraStopCommands = ''
      ${optionalString hasDnat ''
      ${concatStringsSep "\n      " (mapAttrsToList (_n: r:
        "iptables -t nat -D PREROUTING -i ${iface} -p ${r.protocol} --dport ${toString r.listenPort} -j DNAT --to-destination ${r.target} 2>/dev/null || true"
      ) cfg.natRules)}
      iptables -t nat -D POSTROUTING -s ${tunnelCidr} ! -o ${iface} -j MASQUERADE 2>/dev/null || true
      ''}
      iptables -D FORWARD -i ${iface} -j ACCEPT 2>/dev/null || true
      iptables -D FORWARD -o ${iface} -j ACCEPT 2>/dev/null || true
      iptables -t mangle -D FORWARD -i ${iface} -p tcp --tcp-flags SYN,RST SYN -j TCPMSS --clamp-mss-to-pmtu 2>/dev/null || true
      iptables -t mangle -D FORWARD -o ${iface} -p tcp --tcp-flags SYN,RST SYN -j TCPMSS --clamp-mss-to-pmtu 2>/dev/null || true
      iptables -t mangle -D OUTPUT  -o ${iface} -p tcp --tcp-flags SYN,RST SYN -j TCPMSS --clamp-mss-to-pmtu 2>/dev/null || true
    '';
  };
}
