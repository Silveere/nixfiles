# vim: set ts=2 sw=2 et: 
# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running `nixos-help`).

{ config, lib, pkgs, inputs, ... }:

{

  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
      # Encryption
      ./luks.nix
      ./mcserver.nix

      ./impermanence.nix

      ./backup.nix
    ];

  config = {

    fileSystems = lib.mkMerge [
      {
        "/ntfs" = {
          fsType = "ntfs-3g";
          device = "/dev/disk/by-uuid/6AC23F0FC23EDF4F";
          options = [ "auto_cache" "nofail" ];
        };
        "/.btrfsroot" = {
          options = [ "subvol=/" ];
        };
      }

      (lib.genAttrs [ "/.btrfsroot" "/" "/home" "/nix" ] ( fs: {
        options = [ "compress=zstd" ];
      }))
    ];

    # hardware.nvidia.package = lib.mkForce config.boot.kernelPackages.nvidiaPackages.production;
    hardware.nvidia.open = lib.mkForce false;

    specialisation.hyprland.configuration = {
      system.nixos.tags = [ "Hyprland" ];
      nixfiles = {
        session = "hyprland";
      };
    };


    hardware.cpu.intel.updateMicrocode = true;

    services.udev.extraRules = ''
      # motherboard has a faulty USB hub or something; whenever *any* program
      # tries to enumerate USB devices (which is a lot of programs for some
      # reason), it hangs for several seconds. this disables the faulty hub.
      SUBSYSTEMS=="usb", ACTION=="add", KERNEL=="usb2", ATTRS{idVendor}=="1d6b", ATTRS{idProduct}=="0003", ATTRS{serial}=="0000:00:14.0", ATTRS{busnum}=="2", ATTR{authorized}="0"
    '';

    # nixfiles
    nixfiles = {
      profile.workstation.enable = true;
      programs.adb.enable = true;
      workarounds.nvidiaPrimary = true;
      programs.greetd = {
        settings = {
          randr = [ "--output" "HDMI-A-3" "--off" ];
          autologin = false;
          autologinUser = "nullbite";
          autolock = false;
        };
      };
      common.remoteAccess.enable = true;
      common.bootnext = {
        enable = true;
        entries = {
          windows = {
            name = "Windows Boot Manager";
            efiPartUUID = "6fc437f5-b917-42b2-9d5d-1439a14e105b";
            desktopEntry = {
              name = "Windows";
              icon = "microsoft-windows";
            };
          };
        };
      };
      # session = lib.mkDefault "hyprland";
      session = lib.mkDefault "plasma";
      hardware.nvidia.modesetting.enable = true;
      packageSets.gaming.enable = true;
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

    # temporary while i am away from server
    boot.kernelPackages = pkgs.linuxPackages_6_6;

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
  };

}

