{
  disko.devices.disk.sda = {
    type = "disk";

    # Stable disk path (good)
    device = "/dev/disk/by-id/scsi-0QEMU_QEMU_HARDDISK_64198393";

    content = {
      type = "gpt";
      partitions = {
        # BIOS boot partition for GRUB on GPT + SeaBIOS
        biosboot = {
          size = "1M";
          type = "EF02";
        };

        ESP = {
          size = "256M";
          type = "EF00";
          content = {
            type = "filesystem";
            format = "vfat";
            mountpoint = "/boot/efi";
            mountOptions = ["defaults"];
          };
        };

        root = {
          size = "100%";
          type = "8300";
          content = {
            type = "filesystem";
            format = "ext4";
            mountpoint = "/";
            mountOptions = ["defaults" "noatime"];
            extraArgs = ["-L" "nixos-root"];
          };
        };
      };
    };
  };
}
