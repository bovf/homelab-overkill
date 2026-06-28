{
  config,
  pkgs,
  lib,
  ...
}: {
  system.stateVersion = "24.11";

  imports = [
    ./disk-config.nix
  ];

  # Force the kernel to calculate checksums before they leave the VPS
  systemd.services.fix-udp-checksums = {
    description = "Fix UDP checksums for Docker bridge";
    wantedBy = ["multi-user.target"];
    after = ["network.target"];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.ethtool}/bin/ethtool -K enp1s0 tx off rx off";
      RemainAfterExit = true;
    };
  };

  boot.kernel.sysctl = {
    "net.ipv4.ip_forward" = 1;
    "net.ipv6.conf.all.forwarding" = 1;
    "net.ipv4.conf.all.rp_filter" = 0;
    "net.ipv4.conf.default.rp_filter" = 0;
    # Helps with loopback issues when userland-proxy is disabled
    "net.ipv4.conf.all.route_localnet" = 1;

    # WireGuard / high-throughput tunnel buffers. The Linux defaults
    # (rmem_max=wmem_max=208KB, netdev_max_backlog=1000) are sized for a
    # 1990s desktop and starve a busy WG endpoint of socket buffer space
    # during bursts — packets get dropped under the udp_mem watermark
    # before the WG handler can drain them, manifesting as stalls on
    # high-bitrate tunneled streams (e.g. Jellyfin direct-streaming a
    # 21 Mbps remux).
    "net.core.rmem_max" = 26214400; # 25 MiB
    "net.core.wmem_max" = 26214400; # 25 MiB
    "net.core.rmem_default" = 1048576; # 1 MiB
    "net.core.wmem_default" = 1048576; # 1 MiB
    "net.core.netdev_max_backlog" = 250000;
  };

  boot.initrd.availableKernelModules = [
    "virtio_pci"
    "virtio_scsi"
    "virtio_blk"
    "virtio_ring"
    "sd_mod"
    "scsi_mod"
    "sr_mod"
    "ahci"
  ];
  boot.initrd.kernelModules = ["ext4"];

  fileSystems."/" = lib.mkForce {
    device = "/dev/sda3";
    fsType = "ext4";
    options = ["defaults" "noatime"];
  };

  boot.loader = {
    systemd-boot.enable = false;
    grub = {
      enable = lib.mkForce true;
      devices = lib.mkForce ["/dev/sda"];
      fsIdentifier = "uuid";
    };
    efi = {
      canTouchEfiVariables = false;
      efiSysMountPoint = "/boot/efi";
    };
  };

  networking = {
    hostName = lib.mkDefault "pangolin";
    useDHCP = lib.mkDefault true;
  };

  services.chrony.enable = true;

  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "prohibit-password";
      PasswordAuthentication = false;
      PubkeyAuthentication = true;
    };
    ports = [22];
  };

  # Default outbound SSH identity for the VPS itself.
  # Generate the key on the VPS: `ssh-keygen -t ed25519 -f /root/.ssh/theadministrator`.
  # SSH tries this key first; if it's missing or rejected, it falls back to
  # the agent / standard ~/.ssh/id_* keys. Add `IdentitiesOnly yes` to make
  # this the only key that's ever offered.
  programs.ssh.extraConfig = ''
    IdentityFile /root/.ssh/theadministrator
  '';

  users.users.root.openssh.authorizedKeys.keys = [
    # dobry — MacBook Air
    "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDUXtAezrePsCvDPiIe3dvVuGchOic2nF8bBmuN7CEkqMWhf4x+R5RL8XiVi7WzjOaQGPX6jqLVx8ncxx1p1mfPHoORUKU66OrAVknY5897izsixfgfAXdtj04DzEZO9iP4OHFGqjqu+fgeH6Pbh1+WWocRvg3aR6lhLzfqRl4nhYbHSsmWrT8FPcO8fzgTgayL7JrJzpzkFHcwAk1FWseMWRK3jOBwS5fzw/rQbp3od74yfvm7k0IAg8O76gpyi/EwzquykDTdQYRDrnVc/ALNFx6DLI9JDv96vAkk3sqiB7JLZjmKeUa5TetYeONpo+16+Adjm9AEPSrrNw0SRSX1o024VumA3PEn77J4ItOQ9QCKng0p4yRvFWiKse7YsgWX3bHeSXW+D/EJJknB5eLW1E1Xq5yAVMGuYxXOdINb2gaiYWDDTd8+gfbi9/U9i607I1kiEflJzwKfVCx695RjCZRzhpyiiv46lB+JOCqxKDsap6XBZtK6TN9Frmgd9Gzgw9c9ytx7MabLrI39E0Sn4anDKMmmNvbtOu0WEpgmb+0o5o6H+Tqaw9PAwiy3n4/YUQAbGf9tAxdhmWdBINtk7yDIhF2Q8b91sxLVIwnHxBBVJzs4NSxqsP5pt4Zsrr9U2mDPgDdazBSu2SNxp3tF8oxNBhdOBJz4nxgnau236w== dobrynikolov@Dobrys-MacBook-Air.local"

    # engineer
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICoJQa9vHbT65SMInKKKsEaYV7pLZK/oWkoEStXt18F4 engineer@engineer.local"

    # heavy
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIF3+IDT9G8GpMl4ylKF51mjcYec5xUxAES4X6CK4PwHs heavy@heavy"
  ];

  environment.systemPackages = with pkgs; [
    vim
    curl
    wget
    htop
    net-tools
    git
    jq
    ethtool
    # Terminfo so SSH-ing in from modern terminal emulators (Ghostty,
    # Alacritty, Kitty, …) doesn't get "unknown terminal type" on `clear`,
    # `tput`, vim colors, etc.
    ghostty.terminfo
    alacritty.terminfo
    kitty.terminfo
  ];

  services.journald.extraConfig = ''
    Storage=persistent
    MaxRetentionSec=1month
  '';
}
