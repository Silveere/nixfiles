{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) mkOption mkEnableOption mkIf mkDefault optionalString mkOrder;
  cfg = config.nixfiles.common.shell;
  tmux_timeout = 15;

  tmuxAutoExit = false;

  common_functions = shell: ''
    __nixfiles_alias_comma_frequent_commands () {
      history | sed 's:^ \+[0-9]\+ \+::' | grep '^,' | cut -d' ' -f2- | sed 's:^\(-[^ ]\+ \?\)\+::g' | grep . | cut -d' ' -f1 | sort | uniq -c | sort -g
    }

    ${lib.optionalString cfg.replace ''
      __nixfiles_replace_shell () {
        [[ -z "''${NF_NO_EXEC:+x}" ]] && exec -a -fish fish
      }
    ''}

    __nixfiles_tmux_auto_exit () {
      [[ -z "''${NF_NO_TMUX:+x}" ]] || return 0
      ${optionalString tmuxAutoExit ''
        local timeout
        local start
        local end
        timeout=${lib.escapeShellArg (builtins.toString tmux_timeout)}
        start="$(date +%s)"
      ''}
      [[ -z "''${TMUX:+x}" ]] && command -v tmux > /dev/null 2>&1 && tmux new-session || return 0
      # only do it once per shell session
      NF_NO_TMUX=1
      export NF_NO_TMUX
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
      replace = lib.mkEnableOption "" // {
        description = ''
          Whether to replace the interactive bash session with a different
          shell. Currently, this replaces it with `fish`, this may change
          later.
        '';
      };
      tmux = lib.mkEnableOption "" // {
        description = ''
          Whether to automatically start a `tmux` session at shell startup.
        '';
      };
  };

  config = mkIf cfg.enable {
    home.shellAliases = {
      v = "nvim";
      icat = "kitten icat";
      srun = "systemd-run";
      urun = "systemd-run --user";
      grc = "grc --colour=on";
      vn = "cd ~/nixfiles ; nvim -S";

      # start bash normally if i invoke it as a shell command
      bash = "env NF_NO_TMUX=1 NF_NO_EXEC=1 bash";

      # this lets me find commands that i run with comma very frequently so i
      # can install them
      comma-frequent = "__nixfiles_alias_comma_frequent_commands";

      ta = "tmux attach";
    };

    programs.fzf = {
      enable = mkDefault true;
      enableFishIntegration = mkDefault false;
    };
    programs.zoxide.enable = mkDefault true;

    programs.bash = {
      enable = mkDefault true;
      # declare functions at start of bashrc
      bashrcExtra = common_functions "bash";
      initExtra =
        # config.programs.tmux.enable
        lib.optionalString cfg.tmux ''
          __nixfiles_tmux_auto_exit

        ''
        + lib.optionalString cfg.replace ''
          __nixfiles_replace_shell
        ''
        + ''
          export HOME_MANAGER_MANAGED=true;
          [[ -e ~/dotfiles/shell/.bashrc ]] && . ~/dotfiles/shell/.bashrc ]]
          unset HOME_MANAGERR_MANAGED

        '';
    };

    # i like shells
    programs.fish = {
      enable = mkDefault true;
    };

    programs.nushell = {
      enable = mkDefault true;
      shellAliases = {
        vn = lib.mkForce "env false";
      };
    };

    programs.zsh = {
      enable = mkDefault true;
      initContent = lib.mkMerge [
        (mkOrder 450 (common_functions "zsh"))
        # config.programs.tmux.enable
        (lib.mkIf true (mkOrder 500 ''
          __nixfiles_tmux_auto_exit

        ''))
        ''
          export HOME_MANAGER_MANAGED=true
          [[ -e ~/dotfiles/shell/.zshrc ]] && . ~/dotfiles/shell/.zshrc ]]
          unset HOME_MANAGER_MANAGED

        ''
      ];
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
