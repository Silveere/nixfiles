{
  lib,
  pkgs,
  config,
  osConfig ? {},
  ...
}: let
  cfg = config.nixfiles.profile.base;
in {
  # imports = [
  #   ./comma.nix
  # ];
  # home.username = "nullbite";
  # home.homeDirectory = "/home/nullbite";

  options.nixfiles.profile.base = {
    enable = lib.mkEnableOption "base profile";
  };

  config = lib.mkIf cfg.enable {
    nixfiles.programs.comma.enable = true;
    nixfiles.programs.neovim.enable = lib.mkDefault true;
    nixfiles.common.nix.enable = true;
    nixfiles.common.shell.enable = true;

    home.sessionVariables = lib.mkMerge [
      (lib.mkIf config.programs.neovim.enable {
        MANPAGER = "nvim +Man!";
      })

      # configure terminfo since we're probably standalone
      (lib.mkIf (!(osConfig ? environment)) {
        TERMINFO_DIRS = let
          terminfo-dirs = [
            "${config.home.profileDirectory}/share/terminfo"
            "/usr/share/terminfo"
          ];
        in
          builtins.concatStringsSep ":" terminfo-dirs;
      })
    ];

    programs.git = {
      enable = lib.mkDefault true;
      maintenance.enable = lib.mkDefault true;
      # default value is stateVersion dependent, doesn't evaluate after 25.05
      # even if signing isn't configured for some reason
      signing.format = lib.mkDefault "openpgp";
    };

    # this allows `git config --global` commands to work by ensuring the
    # presense of ~/.gitconfig. git will read from both files, and `git config`
    # will not write to ~/.gitconfig when the managed config exists unless
    # ~/.gitconfig also exists
    home.activation.git-create-gitconfig =
      lib.mkIf config.programs.git.enable
      (lib.hm.dag.entryAfter ["writeBoundary"] ''
        _nixfiles_git_create_gitconfig () {
          if ! [[ -a "$HOME/.gitconfig" ]] ; then
            touch "$HOME/.gitconfig"
          fi
        }
        run _nixfiles_git_create_gitconfig
      '');

    programs.btop.enable = lib.mkDefault true;

    programs.ranger = let
      defaultTerminal = "kitty";
      # defaultTerminal =
      #   if config.programs.kitty.enable then "kitty"
      #     else null;
    in {
      enable = lib.mkDefault true;
      settings = lib.mkMerge [
        {
          use_preview_script = lib.mkDefault true;
          preview_files = lib.mkDefault true;
        }
        (lib.mkIf (!(isNull defaultTerminal)) {
          preview_images = lib.mkDefault true;
          preview_images_method = lib.mkDefault defaultTerminal;
        })
      ];
    };

    programs.keychain = {
      enable = lib.mkDefault true;
      enableBashIntegration = lib.mkDefault true;
      enableZshIntegration = lib.mkDefault true;
      extraFlags = [
        "--quiet"
        "--systemd"
        "--inherit"
        "any-once"
        "--noask"
      ];
    };

    # this fixes a lot of theme weirdness
    # this actually breaks home-manager's icon/theme management
    # home.file.".icons".source = config.lib.file.mkOutOfStoreSymlink "${config.xdg.dataHome}/icons";
    # home.file.".themes".source = config.lib.file.mkOutOfStoreSymlink "${config.xdg.dataHome}/themes";

    # some packages defined here may be redundant with packages on a non-NixOS
    # home-manager setup, but it's better to have a consistent environment at
    # the cost of slightly more space
    home.packages = with pkgs; let
      neofetch-hyfetch-shim = writeShellScriptBin "neofetch" ''
        exec "${pkgs.hyfetch}/bin/neowofetch" "$@"
      '';
    in
      [
        # nix stuff
        nvd
        nix-tree
        nh
        nix-output-monitor
        attic-client
        nix-fast-build

        git
        git-lfs
        stow
        curl

        # shell
        ripgrep
        fd
        bat
        moreutils
        grc
        fzf
        pv
        jq
        yq
        lsof
        xxd
        shellcheck

        # for icat on all systems
        kitty.kitten

        # pretty
        hyfetch
        neofetch-hyfetch-shim
        fastfetch

        # files
        restic
        rclone
        rmlint
        ncdu

        # compression
        atool-wrapped
        lzip
        plzip
        lzop
        xz
        zip
        unzip
        arj
        rpm
        cpio
        p7zip

        # other utilities
        tmux
        tmuxp
        openssh
        autossh
        mosh
        btop
        htop
        zoxide
        asciinema
        mtr
        qrencode

        screen
        minicom
        picocom
      ]
      ++ builtins.map (x: lib.hiPrio x) [
        # terminfo (just the ones i'm likely to use)
        kitty.terminfo
        alacritty.terminfo
        termite.terminfo
        tmux.terminfo
      ];
  };
}
