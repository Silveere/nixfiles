{ config, lib, pkgs, options, inputs, outputs, ...}@args:
let
  cfg = config.nixfiles.profile.base;
in
{
  options.nixfiles.profile.base = {
    enable = lib.mkEnableOption "base config";
  };
               # TODO was gonna add something but i forgor and now i'm too lazy
               # to delete this
  config = lib.mkMerge [
    (lib.mkIf cfg.enable {

      nixfiles.common = {
        # Enable my account
        me.enable = lib.mkDefault true;
        # Enable system Nix configuration
        nix.enable = lib.mkDefault true;
      };

      # locale settings
      i18n = {
        defaultLocale = lib.mkDefault "en_US.utf8";
        extraLocaleSettings = {
          LC_ALL = lib.mkDefault config.i18n.defaultLocale;
          LC_CTYPE = lib.mkDefault config.i18n.defaultLocale;
        };
      };

      # Enable flakes
      nix.settings.experimental-features = ["nix-command" "flakes" ];

      # Allow unfree packages
      nixpkgs.config.allowUnfree = true;

      # this allows non-NixOS binaries to run on NixOS.
      programs.nix-ld = {
        enable = true;
        libraries = with pkgs; [
          # don't know if i need this right now but i'm saving it for later
          # libstdcxx5
        ];
      };

      # networking.hostName = "nixos"; # Define your hostname.
      # Pick only one of the below networking options.
      # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.
      # FIXME find somewhere else to put this
      networking.networkmanager.enable = lib.mkDefault true;  # Easiest to use and most distros use this by default.

      # List packages installed in system profile. To search, run:
      # $ nix search wget
      environment.systemPackages = with pkgs; let
        neofetch-hyfetch-shim = writeShellScriptBin "neofetch" ''
          exec "${hyfetch}/bin/neowofetch" "$@"
        '';
      in [
        neovim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
        tmux
        wget
        curl
        git
        git-lfs
        stow
        zsh
        ntfs3g
        openssh
        sshfs
        file
        tree
        moreutils
        libarchive

        fd
        ripgrep
        sbctl # TODO move this elsewhere
        comma
        nil

        # network utilities
        inetutils
        socat
        nmap
        hping
        dig
        dig.dnsutils

        # system utilities
        htop
        lshw
        pciutils
        usbutils
        compsize
        efibootmgr
        ncdu
        btdu
        rmlint

        # nix utilities
        nix-du
        graphviz # for nix-du
        nvd
        nix-diff

        # secrets
        age
        pass
        sops

        # etc
        hyfetch
        neofetch-hyfetch-shim
        atool-wrapped
        restic
        rclone
        pv

        # kitty compatibility on all systems
        kitty.terminfo
      ];

      # Needed for Kvantum themes to be detected
      environment.pathsToLink = [ "/share/Kvantum" ];

      programs.neovim = {
        enable = lib.mkDefault true;
        defaultEditor = lib.mkDefault true;
      };

      programs.ssh.enableAskPassword = lib.mkDefault false;
      programs.fuse.userAllowOther = lib.mkDefault true;

      programs.gnupg.agent = {
        enable = lib.mkDefault true;
        enableSSHSupport = lib.mkDefault false;
      };

      boot.loader.systemd-boot.configurationLimit = lib.mkDefault 15;

      # see:
      # https://redd.it/vdz86j
      # https://github.com/NixOS/nixpkgs/commit/15d761a525a025de0680b62e8ab79a9d183f313d
      # https://discourse.nixos.org/t/why-does-multi-user-target-depend-on-network-online-target/33565

      systemd.targets.network-online.wantedBy = lib.mkForce [];
    })
  ];
}
