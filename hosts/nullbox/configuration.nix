# vim: set ts=2 sw=2 et: 
# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running `nixos-help`).

{ config, lib, pkgs, ... }:

{

  fileSystems."/ntfs" = {
    fsType = "ntfs-3g";
    device = "/dev/disk/by-uuid/6AC23F0FC23EDF4F";
  };

  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

  # cryptsetup
  boot.initrd.luks.devices = {
    lvmroot = {
      device="/dev/disk/by-uuid/85b5f22e-0fa5-4f0d-8fba-f800a0b41671";
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

  networking.wg-quick.interfaces.wg0 = {
    configFile = "/etc/wireguard/wg0.conf";
    autostart = true;
  };

  # Use the systemd-boot EFI boot loader.
  # boot.loader.systemd-boot.enable = true;
  # boot.loader.efi.canTouchEfiVariables = true;
  # see custom-hardware-configuration.nix


  # networking.hostName = "nixos"; # Define your hostname.
  networking.hostName = "nullbox";
  # Pick only one of the below networking options.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.
  # networking.networkmanager.enable = true;  # Easiest to use and most distros use this by default.

  # Set your time zone.
   time.timeZone = "America/New_York";


  # Copy the NixOS configuration file and link it from the resulting system
  # (/run/current-system/configuration.nix). This is useful in case you
  # accidentally delete configuration.nix.
  # system.copySystemConfiguration = true;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It's perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "23.11"; # Did you read the comment?

}

