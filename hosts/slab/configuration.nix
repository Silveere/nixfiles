# vim: set ts=2 sw=2 et foldmethod=marker: 
# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).

{ config, lib, pkgs, vars, ... }:

{
  # nix.settings.experimental-features = ["nix-command" "flakes" ];

  fileSystems = lib.mkMerge [
    {
      "/ntfs" = {
        fsType = "ntfs-3g";
        device = "/dev/disk/by-uuid/028A49020517BEA9";
      };
      "/.btrfsroot" = {
        options = [ "subvol=/" ];
      };
    }

    (lib.genAttrs [ "/.btrfsroot" "/" "/home" "/nix" ] ( fs: {
      options = [ "compress=zstd" ];
    }))
  ];

  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix

      ../../system # nixfiles modules
      ./nvidia-optimus.nix
    ];
  nixfiles = {
    profile.pc.enable = true;
    common.remoteAccess.enable = true;
    hardware.opengl.enable = true;
    packageSets = {
      gaming.enable = true;
      fun.enable = true;
    };
    sessions.hyprland.enable = true;
    sessions.plasma.enable = lib.mkDefault false;
    programs = {
      adb.enable = true;
    };
  };


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
      # grr oem efi partitions
      configurationLimit = 4;
    };
  };

  systemd.targets = lib.genAttrs ["suspend" "hybrid-sleep" "suspend-then-hibernate"] (_: {
    enable = false;
    unitConfig.DefaultDependencies = "no";
  });

  services.xserver.videoDrivers = ["amdgpu"];

  # {{{ old config
  # Use the systemd-boot EFI boot loader.
  # boot.loader.systemd-boot.enable = true;
  # boot.loader.efi.canTouchEfiVariables = true;
  # see custom-hardware-configuration.nix


  # networking.hostName = "nixos"; # Define your hostname.
  # Pick only one of the below networking options.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.
  # networking.networkmanager.enable = true;  # Easiest to use and most distros use this by default.
  # }}}

  # Set your time zone.
  time.timeZone = vars.mobileTimeZone;

  services.asusd.enable = true;

  # {{{ old config
  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Select internationalisation properties.
  # i18n.defaultLocale = "en_US.UTF-8";
  # console = {
  #   font = "Lat2-Terminus16";
  #   keyMap = "us";
  #   useXkbConfig = true; # use xkb.options in tty.
  # };

  # Enable the X11 windowing system.
  # services.xserver.enable = true;

  # services.xserver.displayManager.sddm.enable = true;
  # services.xserver.desktopManager.plasma5.enable = true;


  # Enable flatpak
  # services.flatpak.enable = true;
  

  # Configure keymap in X11
  # services.xserver.xkb.layout = "us";
  # services.xserver.xkb.options = "eurosign:e,caps:escape";

  # Enable CUPS to print documents.
  # services.printing.enable = true;

  # Enable sound.
  # sound.enable = true;
  # hardware.pulseaudio.enable = true;
  # security.rtkit.enable = true;
  # services.pipewire = {
  #   enable = true;
  #   alsa.enable = true;
  #   alsa.support32Bit = true;
  #   pulse.enable = true;
  #   jack.enable = true;
  # };
  

  # Enable touchpad support (enabled default in most desktopManager).
  # services.xserver.libinput.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  # users.users.alice = {
  #   isNormalUser = true;
  #   extraGroups = [ "wheel" ]; # Enable ‘sudo’ for the user.
  #   packages = with pkgs; [
  #     firefox
  #     tree
  #   ];
  # };

  # users.users.nullbite = {
  #   isNormalUser = true;
  #   extraGroups = [ "wheel" ];
  #   packages = with pkgs; [
  #     firefox
  #     keychain
  #   ];
  #   initialPassword = "changeme";
  #   shell = pkgs.zsh;
  # };


  # shell config
  # programs.zsh.enable = true;
  # programs.fzf = {
  #   keybindings = true;
  #   fuzzyCompletion = true;
  # };

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  # environment.systemPackages = with pkgs; [
  #   neovim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
  #   wget
  #   curl
  #   git
  #   stow
  #   zsh
  #   ntfs3g

  #   fd
  #   ripgrep
  #   sbctl
  #   comma
  # ];

  # Allow unfree packages
  # nixpkgs.config.allowUnfree = true;

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  # services.openssh.enable = true;
  # services.openssh = {
  #   enable = true;
  #   openFirewall = true;
  #   settings = {

  #   };
  # };

  # services.tailscale.enable = true;
  # }}}

  # Open ports in the firewall.
  networking.firewall.allowedTCPPorts = [ 22 ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

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

