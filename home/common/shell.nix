{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) mkOption mkEnableOption mkIf mkDefault optionalString;
  cfg = config.nixfiles.common.shell;
  tmux_timeout = 15;

  tmuxAutoExit = false;

  common_functions = shell: ''
    __nixfiles_alias_comma_frequent_commands () {
      history | sed 's:^ \+[0-9]\+ \+::' | grep '^,' | cut -d' ' -f2- | sed 's:^\(-[^ ]\+ \?\)\+::g' | grep . | cut -d' ' -f1 | sort | uniq -c | sort -g
    }
    __nixfiles_tmux_auto_exit () {
      ${optionalString tmuxAutoExit ''
        local timeout
        local start
        local end
        timeout=${lib.escapeShellArg (builtins.toString tmux_timeout)}
        start="$(date +%s)"
      ''}
      [[ -z "''${TMUX:+x}" ]] && command -v tmux > /dev/null 2>&1 && tmux new-session || return 0
      ${optionalString tmuxAutoExit ''
        end="$(date +%s)"

        if [[ "$(( "$end" - "$start" ))" -gt "$timeout" ]]
        then
          echo exiting in 5 seconds. press ^C to cancel...
          trap : INT
          sleep 5 || { trap - INT; echo exit cancelled. ; return 0; }
          exit 0
        fi
      ''}
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
      vn = "cd ~/nixfiles; nvim";

      # this lets me find commands that i run with comma very frequently so i
      # can install them
      comma-frequent = "__nixfiles_alias_comma_frequent_commands";

      ta = "tmux attach";
    };

    programs.fzf.enable = mkDefault true;
    programs.zoxide.enable = mkDefault true;

    programs.bash = {
      enable = mkDefault true;
      # declare functions at start of bashrc
      bashrcExtra = common_functions "bash";
      initExtra =
        # config.programs.tmux.enable
        lib.optionalString true ''
          __nixfiles_tmux_auto_exit

        ''
        + ''
          export HOME_MANAGER_MANAGED=true;
          [[ -e ~/dotfiles/shell/.bashrc ]] && . ~/dotfiles/shell/.bashrc ]]
          unset HOME_MANAGERR_MANAGED

        '';
    };
    programs.zsh = {
      enable = mkDefault true;
      initContent = (
        common_functions "zsh"
        # config.programs.tmux.enable
        + (lib.optionalString true ''
          __nixfiles_tmux_auto_exit

        '')
        + ''
          export HOME_MANAGER_MANAGED=true
          [[ -e ~/dotfiles/shell/.zshrc ]] && . ~/dotfiles/shell/.zshrc ]]
          unset HOME_MANAGER_MANAGED

        ''
      );
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
