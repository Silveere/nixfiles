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

    # this makes xdg.mimeApps overwrite mimeapps.list if it has been touched by something else
    xdg.configFile."mimeapps.list".force = true;

    # TODO move this stuff to a zsh.nix or something; this is just a quick fix so home.sessionVariables works
    home.shellAliases = {
      v = "nvim";
    };
    programs.fzf.enable = true;
    programs.fzf.enableZshIntegration = true;
    programs.zsh = {
      enable = true;
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

    # this fixes a lot of theme weirdness
    home.file.".icons".source = config.lib.file.mkOutOfStoreSymlink "${config.xdg.dataHome}/icons";
    home.file.".themes".source = config.lib.file.mkOutOfStoreSymlink "${config.xdg.dataHome}/themes";

    home.packages = with pkgs; [
      btop
      fzf
      zoxide
      tmux
    ];
  };
}
