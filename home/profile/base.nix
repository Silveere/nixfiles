{ lib, pkgs, config, osConfig ? { }, ... }:
let
  cfg = config.nixfiles.profile.base;
in
{
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
    nixfiles.common.nix.enable = true;

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
        in builtins.concatStringsSep ":" terminfo-dirs;
      })
    ];


    # TODO move this stuff to a shell.nix or something; this is just a quick
    # fix so home.sessionVariables works
    home.shellAliases = {
      v = "nvim";
      icat = "kitten icat";
    };
    programs.fzf.enable = lib.mkDefault true;
    programs.fzf.enableZshIntegration = lib.mkDefault true;
    programs.fzf.enableBashIntegration = lib.mkDefault true;

    programs.bash = {
      enable = lib.mkDefault true;
      initExtra = ''
        export HOME_MANAGER_MANAGED=true;
        [[ -e ~/dotfiles/shell/.bashrc ]] && . ~/dotfiles/shell/.bashrc ]]
        unset HOME_MANAGERR_MANAGED
      '';
    };
    programs.zsh = {
      enable = lib.mkDefault true;
      initExtra = ''
        export HOME_MANAGER_MANAGED=true
        [[ -e ~/dotfiles/shell/.zshrc ]] && . ~/dotfiles/shell/.zshrc ]]
        unset HOME_MANAGER_MANAGED
      '';
      oh-my-zsh = {
        enable = lib.mkDefault true;
        theme = "robbyrussell";
        extraConfig = ''
          DISABLE_MAGIC_FUNCTIONS="true"
        '';
        plugins = [
          "git"
        ];
      };
    };

    programs.btop.enable = lib.mkDefault true;

    programs.ranger = let
      defaultTerminal = "kitty";
      # defaultTerminal =
      #   if config.programs.kitty.enable then "kitty"
      #     else null;

    in {
      enable = lib.mkDefault true;
      settings = lib.mkMerge [{
        use_preview_script = lib.mkDefault true;
        preview_files = lib.mkDefault true;
      } (lib.mkIf (!(isNull defaultTerminal)) {
        preview_images = lib.mkDefault true;
        preview_images_method = lib.mkDefault defaultTerminal;
      })];
    };

    programs.keychain = {
      enable = lib.mkDefault true;
      enableBashIntegration = lib.mkDefault true;
      enableZshIntegration = lib.mkDefault true;
      extraFlags = [
        "--quiet"
        "--systemd"
        "--inherit" "any-once"
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
    programs.neovim = {
      enable = lib.mkDefault true;
      vimAlias = lib.mkDefault true;
      withPython3 = lib.mkDefault true;
      defaultEditor = lib.mkDefault true;
    };

    home.packages = with pkgs; let
      neofetch-hyfetch-shim = writeShellScriptBin "neofetch" ''
        exec "${pkgs.hyfetch}/bin/neowofetch" "$@"
      '';
    in [
      # nix stuff
      nvd
      nix-tree
      nh
      nix-output-monitor

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

      # for icat on all systems
      kitty.kitten

      # terminfo (just the ones i'm likely to use)
      kitty.terminfo
      alacritty.terminfo
      termite.terminfo
      tmux.terminfo

      # pretty
      hyfetch
      neofetch-hyfetch-shim

      # files
      restic
      rclone
      rmlint
      ncdu

      # other utilities
      tmux
      mosh
      btop
      htop
      zoxide
      asciinema

    ];
  };
}
