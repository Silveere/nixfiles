{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) mkOption mkEnableOption mkIf mkDefault;
  cfg = config.nixfiles.common.shell;

  common_functions = shell: ''
    __nixfiles_alias_comma_frequent_commands () {
      history | sed 's:^ \+[0-9]\+ \+::' | grep '^,' | cut -d' ' -f2- | sed 's:^\(-[^ ]\+ \?\)\+::g' | grep . | cut -d' ' -f1 | sort | uniq -c | sort -g
    }
  '';
in {
  options.nixfiles.common.shell = {
    enable =
      lib.mkEnableOption ""
      // {
        description = "Whether to enable the nixfiles shell configuration.";
      };
  };

  config = mkIf cfg.enable {
    home.shellAliases = {
      v = "nvim";
      icat = "kitten icat";
      srun = "systemd-run";
      urun = "systemd-run --user";
      grc = "grc --colour=on";

      # this lets me find commands that i run with comma very frequently so i
      # can install them
      comma-frequent = "__nixfiles_alias_comma_frequent_commands";
    };
    programs.fzf.enable = mkDefault true;
    programs.fzf.enableZshIntegration = mkDefault true;
    programs.fzf.enableBashIntegration = mkDefault true;

    programs.bash = {
      enable = mkDefault true;
      # declare functions at start of bashrc
      bashrcExtra = common_functions "bash";
      initExtra = ''
        export HOME_MANAGER_MANAGED=true;
        [[ -e ~/dotfiles/shell/.bashrc ]] && . ~/dotfiles/shell/.bashrc ]]
        unset HOME_MANAGERR_MANAGED
      '';
    };
    programs.zsh = {
      enable = mkDefault true;
      initExtra =
        ''
          export HOME_MANAGER_MANAGED=true
          [[ -e ~/dotfiles/shell/.zshrc ]] && . ~/dotfiles/shell/.zshrc ]]
          unset HOME_MANAGER_MANAGED
        ''
        + common_functions "zsh";
      oh-my-zsh = {
        enable = mkDefault true;
        theme = "robbyrussell";
        extraConfig = ''
          DISABLE_MAGIC_FUNCTIONS="true"
        '';
        plugins = [
          "git"
        ];
      };
    };
  };
}
