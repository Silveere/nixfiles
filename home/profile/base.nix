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

    home.packages = with pkgs; [
      btop
      fzf
      zoxide
      tmux
    ];
  };
}
