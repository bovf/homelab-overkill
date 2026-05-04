# Copy the content of your current hardware-configuration.nix here
# This is the same file, just moved to the new location
{ config, lib, modulesPath, ... }:

{
  imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

  boot.initrd.availableKernelModules = [ "xhci_pci" "ahci" "nvme" "usb_storage" "sd_mod" "rtsx_pci_sdmmc" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-intel" ];
  boot.extraModulePackages = [ ];

  # Block the simpledrm kernel module — its phantom DRM device under
  # /dev/dri/by-path/ collides with the Intel device plugin's container
  # bind-mount when scheduling Jellyfin (gpu.intel.com/i915 resource).
  # Headless server has no need for framebuffer console.
  boot.blacklistedKernelModules = [ "simpledrm" ];

  swapDevices = [ ];

  networking.useDHCP = lib.mkDefault true;
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
