{ config, lib, pkgs, options, inputs, ...}@args:
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

      # Enable my account
      nixfiles.common.me.enable = lib.mkDefault true;

      # locale settings
      i18n = {
        defaultLocale = lib.mkDefault "en_US.UTF-8";
        extraLocaleSettings = {
          LC_ALL = lib.mkDefault "en_US.UTF-8";
        };
      };

      # Enable flakes
      nix.settings.experimental-features = ["nix-command" "flakes" ];

      # fallback to building locally if binary cache fails (home-manager should be
      # able to handle simple rebuilds offline)
      nix.settings.fallback = true;

      # Allow unfree packages
      nixpkgs.config.allowUnfree = true;

      # networking.hostName = "nixos"; # Define your hostname.
      # Pick only one of the below networking options.
      # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.
      networking.networkmanager.enable = lib.mkDefault true;  # Easiest to use and most distros use this by default.

      # List packages installed in system profile. To search, run:
      # $ nix search wget
      environment.systemPackages = with pkgs; [
        neovim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
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

        # system utilities
        htop
        lshw
        pciutils

        # nix utilities
        nix-du
        graphviz # for nix-du

        # secrets
        age
        pass
        sops
      ];

      programs.neovim.defaultEditor = lib.mkDefault true;

      # this makes comma and legacy nix utils use the flake nixpkgs for ABI
      # compatibility becasue once `, vkcube` couldn't find the correct opengl
      # driver or something (also it reduces the download size of temporary shell
      # closures)
      nix.nixPath = [ "nixpkgs=${inputs.nixpkgs}" ] ++ options.nix.nixPath.default;

      programs.ssh.enableAskPassword = lib.mkDefault false;
      programs.fuse.userAllowOther = lib.mkDefault true;

      programs.gnupg.agent = {
        enable = lib.mkDefault true;
        enableSSHSupport = lib.mkDefault true;
      };

      boot.loader.systemd-boot.configurationLimit = lib.mkDefault 15;
    })
  ];
}
