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
  tmuxAutoAttach = true;

  common_functions = shell: ''
    __nixfiles_alias_comma_frequent_commands () {
      history | sed 's:^ \+[0-9]\+ \+::' | grep '^,' | cut -d' ' -f2- | sed 's:^\(-[^ ]\+ \?\)\+::g' | grep . | cut -d' ' -f1 | sort | uniq -c | sort -g
    }

    ${lib.optionalString cfg.replace ''
      __nixfiles_replace_shell () {
        [[ -z "''${NF_NO_EXEC:+x}" ]] && {
          export NF_NO_EXEC=1
          exec -a -fish fish
        };
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
      ${
      if tmuxAutoAttach
      then ''
        [[ -z "''${TMUX:+x}" && -z "''${SSH_CONNECTION:+x}" ]] && command -v tmux > /dev/null 2>&1 && {
            tmux attach-session || tmux new-session;
          } || return 0
      ''
      else ''
        [[ -z "''${TMUX:+x}" ]] && command -v tmux > /dev/null 2>&1 && tmux new-session || return 0
      ''
    }
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
    replace =
      lib.mkEnableOption ""
      // {
        description = ''
          Whether to replace the interactive bash session with a different
          shell. Currently, this replaces it with `fish`, this may change
          later.
        '';
      };
    tmux =
      lib.mkEnableOption ""
      // {
        description = ''
          Whether to automatically start a `tmux` session at shell startup.
        '';
      };
  };

  config = mkIf cfg.enable {
    home.shellAliases = {
      v = "nvim";
      vgit = "nvim +Git +only";
      icat = "kitten icat";
      srun = "systemd-run";
      urun = "systemd-run --user";
      userctl = "systemctl --user";
      grc = "grc --colour=on";
      vn = "cd ~/nixfiles ; nvim -S";
      gh = "env PAGER='nvim -R +set\\ nowrap\\ ic' gh";
      cr = "cd \"$(git rev-parse --show-toplevel)\"";
      cx = ''cd "$(tmux display-message -p '#{session_path}')"'';
      tmpdir = ''cd "$(mktemp -d)"'';

      gdl = ''gallery-dl --config-toml "$HOME/dotfiles/termux/.config/gallery-dl/termux.toml" -D .'';

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
      interactiveShellInit = ''
        fish_config theme choose "Catppuccin Mocha"
      '';

      # this is broken right now for theme plugins
      # plugins = [
      #   { name = "catppuccin";
      #     inherit (pkgs.nvfetcherSources.catppuccin-fish) src; }
      # ];
      shellAbbrs = let
        rsync = "rsync -rlptgoDvzzi --partial-dir=.rsync --info=progress2";
      in {
        nhos = {
          regex = "^nh([oh][stbB])$";
          function = "__fish_abbr_nhos";
        };
        "!!" = {
          position = "anywhere";
          function = "__fish_abbr_last";
        };

        rsy = "${rsync}";
        rsyd = "${rsync} --delete -n";
        cr = {
          function = "__fish_abbr_cr";
          setCursor = "%%FISH_CURSOR%%";
        };
        cx = {
          function = "__fish_abbr_cx";
          setCursor = "%%FISH_CURSOR%%";
        };
        "=cx" = {
          position = "anywhere";
          function = "__fish_abbr_cx_q";
          setCursor = "%%FISH_CURSOR%%";
        };
        "=cr" = {
          position = "anywhere";
          function = "__fish_abbr_cr_q";
          setCursor = "%%FISH_CURSOR%%";
        };
      };
      functions = {
        __git_root = ''git rev-parse --show-toplevel'';
        __tmux_root = ''tmux display-message -p '#{session_path}' '';

        __fish_abbr_cr_q = ''echo (__git_root)/%%FISH_CURSOR%%'';
        __fish_abbr_cx_q = ''echo (__tmux_root)/%%FISH_CURSOR%%'';
        __fish_abbr_cr = "echo cd (__fish_abbr_cr_q)";
        __fish_abbr_cx = "echo cd (__fish_abbr_cx_q)";

        __fish_abbr_last = "echo $history[1]";
        __fish_abbr_nhos = ''
          set -f nh_cat
          set -f nh_opt
          echo $argv[1] | string match -grm1 '^nh(?<nh_cat>.)(?<nh_opt>.)$' > /dev/null
          printf "nh "
          switch $nh_cat
              case o
                  printf "os "
              case h
                  printf "home "
          end

          switch $nh_opt
              case s
                  printf "switch"
              case t
                  printf "test"
              case b
                  printf "boot"
              case B
                  printf "build"
          end
        '';
      };
    };

    xdg.configFile."fish/completions/nix.fish" = {
      source = ./nix-completions.fish;
    };

    xdg.configFile."fish/themes" = {
      source = pkgs.symlinkJoin {
        name = "fish-themes";
        stripPrefix = "/themes";
        paths = [
          pkgs.nvfetcherSources.catppuccin-fish.src
        ];
      };
    };

    programs.nushell = {
      enable = mkDefault true;
      shellAliases = {
        vn = lib.mkForce "env false";
        cr = lib.mkForce "env false";
        cx = lib.mkForce "env false";
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
