# vim: set ts=2 sw=2 et: 
{ config, lib, pkgs, modulesPath, ... }:

{
  networking.hostName = "slab";

  # cryptsetup
  boot.initrd.luks.devices = {
    lvmroot = {
      device="/dev/disk/by-uuid/2872c0f0-e544-45f0-9b6c-ea022af7805a";
      allowDiscards = true;
      fallbackToPassword = true;
      preLVM = true;
    };
  };

  # bootloader setup
  boot.loader = {
    efi = {
      canTouchEfiVariables = true;
      efiSysMountPoint = "/boot";
    };
    # grub = {
    #   enable = true;
    #   efiSupport = true;
    #   device = "nodev";
    # };
    systemd-boot = {
      enable = true;
      netbootxyz.enable = true;
      memtest86.enable = true;
    };
  };

  services.supergfxd.enable = true;

  # Enable OpenGL
  hardware.opengl = {
    enable = true;
    driSupport = true;
    driSupport32Bit = true;
  };

  # Load nvidia driver for Xorg and Wayland
  services.xserver.videoDrivers = ["amdgpu" "nvidia"];

  hardware.nvidia = {

    # Modesetting is required.
    modesetting.enable = false;

    # Nvidia power management. Experimental, and can cause sleep/suspend to fail.
    powerManagement.enable = false;
    # Fine-grained power management. Turns off GPU when not in use.
    # Experimental and only works on modern Nvidia GPUs (Turing or newer).
    powerManagement.finegrained = false;

    # Use the NVidia open source kernel module (not to be confused with the
    # independent third-party "nouveau" open source driver).
    # Support is limited to the Turing and later architectures. Full list of 
    # supported GPUs is at: 
    # https://github.com/NVIDIA/open-gpu-kernel-modules#compatible-gpus 
    # Only available from driver 515.43.04+
    # Currently alpha-quality/buggy, so false is currently the recommended setting.
    open = false;

    # Enable the Nvidia settings menu,
    # accessible via `nvidia-settings`.
    nvidiaSettings = true;

    # Optionally, you may need to select the appropriate driver version for your specific GPU.
    package = config.boot.kernelPackages.nvidiaPackages.stable;

    prime = {
      offload = {
        enable = true;
        enableOffloadCmd = true;
      };
      amdgpuBusId = "PCI:07:00:0";
      nvidiaBusId = "PCI:01:00:0";
    };
  };

  services.syncthing = {
    enable = true;
    user = "nullbite";
    dataDir = "/home/nullbite/Documents";
    configDir = "/home/nullbite/.config/syncthing";
  };

  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
  };
}
