{
  pkgs,
  config,
  lib,
  ...
}: let
  cfg = config.nixfiles.profile.pc;
  inherit (lib) mkDefault;
in {
  options.nixfiles.profile.pc.enable =
    lib.mkEnableOption "minimal PC profile"
    // {
      description = ''
        Whether to enable the minimal PC profile. This profile configures basic
        system configuration for physical PCs, such as enabling sound and
        Bluetooth support.
      '';
    };
  config = lib.mkIf cfg.enable {
    nixfiles.profile.base.enable = lib.mkDefault true;

    nixfiles.binfmt.enable = lib.mkDefault true;

    # networking.hostName = "nixos"; # Define your hostname.
    # Pick only one of the below networking options.
    # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.
    # FIXME find somewhere else to put this
    networking.networkmanager.enable = lib.mkDefault true; # Easiest to use and most distros use this by default.

    # contains icons for bootnext desktop entries (the Windows icon); there's
    # probably no reason to *not* include this.
    environment.systemPackages = with pkgs; [
      nixfiles-assets
    ];

    # enable option sets
    nixfiles = {
      hardware = {
        bluetooth.enable = mkDefault true;
        sound.enable = mkDefault true;
      };
      kernel.zswap.enable = mkDefault true;
    };

    boot.kernel.sysctl = {
      # enable sysrq
      "kernel.sysrq" = mkDefault 1;
      # more responsive for desktop use
      "vm.swappiness" = mkDefault 10;
    };

    # enable filesystems
    boot.supportedFilesystems = {
      # not yet; need kernel 6.7. update the lts kernel first.
      # bcachefs = mkDefault true;
      cifs = mkDefault true;
      ext4 = mkDefault true;
      ecryptfs = mkDefault true;
      exfat = mkDefault true;
      f2fs = mkDefault true;
      # nfs causes a startup delay
      # nfs = mkDefault true;
      squashfs = mkDefault true;
      vfat = mkDefault true;
      xfs = mkDefault true;
    };

    # probably unnecessary, this will be enabled by whatever session i use
    # Enable the X11 windowing system.
    # services.xserver.enable = true;

    # this solves some inconsistent behavior with xdg-open
    xdg.portal.xdgOpenUsePortal = lib.mkDefault true;

    # Enable CUPS to print documents.
    services.printing = {
      enable = mkDefault true;
      cups-pdf.enable = mkDefault true;
    };
  };
}
