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


    # TODO move this stuff to a zsh.nix or something; this is just a quick fix so home.sessionVariables works
    home.shellAliases = {
      v = "nvim";
      icat = "kitty +kitten icat";
    };
    programs.fzf.enable = lib.mkDefault true;
    programs.fzf.enableZshIntegration = lib.mkDefault true;
    programs.fzf.enableBashIntegration = lib.mkDefault true;
    programs.zsh = {
      enable = lib.mkDefault (!config.programs.bash.enable);
      initExtra = ''
        export HOME_MANAGER_MANAGED=true
        [[ -e ~/dotfiles/shell/.zshrc ]] && . ~/dotfiles/shell/.zshrc ]]
        unset HOME_MANAGER_MANAGED
      '';
      oh-my-zsh = {
        enable = true;
        theme = "robbyrussell";
        extraConfig = ''
          DISABLE_MAGIC_FUNCTIONS="true"
        '';
        plugins = [
          "git"
        ];
      };
    };

    programs.keychain = {
      enable = lib.mkDefault true;
      enableBashIntegration = lib.mkDefault true;
      enableZshIntegration = lib.mkDefault true;
      extraFlags = [
        "--quiet"
        "--systemd"
      ];
    };

    # this fixes a lot of theme weirdness
    home.file.".icons".source = config.lib.file.mkOutOfStoreSymlink "${config.xdg.dataHome}/icons";
    home.file.".themes".source = config.lib.file.mkOutOfStoreSymlink "${config.xdg.dataHome}/themes";

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
      btop
      htop
      fzf
      zoxide
      tmux
      restic
      rclone
      rmlint
      pv
      ncdu
      rmlint

      git
      git-lfs
      stow
      curl

      ripgrep
      fd
      bat
      moreutils
      grc

      # for icat on all systems
      kitty.kitten

      # pretty
      hyfetch
      neofetch-hyfetch-shim
    ];
  };
}
