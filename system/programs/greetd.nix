{ pkgs, config, lib, options, ... }:
let
  cfg = config.nixfiles.programs.greetd;
  inherit (lib) types optional optionals escapeShellArg escapeShellArgs;
  inherit (types) bool enum nullOr str path listOf;
  inherit (builtins) isNull;
  optionalsSet = val: optionals (!(isNull val));
  optionalSet = val: optional (!(isNull val));
  sessions = config.services.displayManager.sessionData.desktops;
  xsessions = "${sessions}/share/xsessions";
  wayland-sessions = "${sessions}/share/wayland-sessions";

  loginwrap=pkgs.writeShellScriptBin "loginwrap" ''
    exec "$SHELL" -lc 'exec "$@"' "login-wrapper" "$@"
  '';

  mkPresetOption = x: lib.mkOption {
    description = "${x} greetd configuration";
    type = bool;
    default = false;
  };
in
{
  config = lib.mkIf cfg.enable {
    assertions = lib.optionals cfg.settings.autologin [
      {
        assertion = ! builtins.isNull cfg.settings.autologinUser;
        message = "greetd: Auto-login is enabled but no user is configured";
      }
      {
        assertion = ! builtins.isNull cfg.settings.command;
        message = "greetd: Auto-login is enabled but no login command is configured";
      }
    ];

    environment.systemPackages = [ loginwrap ];
    services.greetd = {
      enable = true;
      settings = {
        initial_session = lib.mkIf cfg.settings.autologin {
          command = cfg.settings.finalCommand;
          user = cfg.settings.autologinUser;
        };

        default_session = lib.mkMerge [

          # tuigreet configuration
          (lib.mkIf cfg.presets.tuigreet.enable {
            command = let
              st = cfg.settings;
              args = [ "${pkgs.greetd.tuigreet}/bin/tuigreet" "--asterisks" "--remember" "--remember-session"
              "--sessions" "${xsessions}:${wayland-sessions}"
              ]
                ++ optionalsSet st.greeting [ "--greeting" st.greeting ]
                ++ optional st.time "--time" 
                ++ optionalsSet st.command [ "--cmd" st.finalCommand ]
                # i think tuigreet might be outdated on nix. disable this because it's not a valid option
                # ++ optionalsSet st.loginShell [ "--session-wrapper" "loginwrap" ]
                ;
            in lib.escapeShellArgs args;
          })

        ];
      };
    };

    # regreet config (it is configured through an upstream module; the only
    # greetd-specific config set is default_session, so we can configure it
    # here instead of above.)
    programs.regreet = let
      # lets us use wlr-randr
      wrapperPackage = pkgs.writeShellScriptBin "regreet-wrapper" ''
        ${cfg.settings.graphicalInit}

        exec ${escapeShellArg (lib.getExe pkgs.greetd.regreet)} "$@"
      '';
    in lib.mkIf cfg.presets.regreet.enable {
      enable = lib.mkDefault true;
      package = wrapperPackage;
      settings = {
        background.path = cfg.settings.wallpaper;
        fit = lib.mkDefault "Fill";
        appearance.greeting_msg = cfg.settings.greeting;
      };
    };

    security.pam.services.greetd = {
      kwallet.enable = lib.mkIf config.services.desktopManager.plasma6.enable true;
    };

    systemd.tmpfiles.settings."10-regreet" =
      let
        defaultConfig = {
          user = "greeter";
          group = config.users.users.${config.services.greetd.settings.default_session.user}.group;
          mode = "0755";
        };
      in lib.mkIf config.programs.regreet.enable
      {
        "/var/log/regreet".d = defaultConfig;
        "/var/cache/regreet".d = defaultConfig;
        "/var/lib/regreet".d = defaultConfig;
      };


    # self config
    nixfiles.programs.greetd = {
      presets.${cfg.preset}.enable = true;
      settings.graphicalInit = lib.optionalString (cfg.settings.randr != null) ''
        ${lib.getExe pkgs.wlr-randr} ${escapeShellArgs cfg.settings.randr}
      '';
    };
  };

  options.nixfiles.programs.greetd = {
    enable = lib.mkEnableOption "greetd configuration";

    preset = lib.mkOption {
      description = "greetd configuration to enable (shorthand for presets.<preset>.enable)";
      type = enum (lib.mapAttrsToList (name: value: name) options.nixfiles.programs.greetd.presets);
      default = "regreet";
    };

    settings = {
      greeting = lib.mkOption {
        description = "Greeting to show on the chosen greeter (if configurable)";
        type = nullOr str;
        default = "log in pwease!! uwu";
        example = "something boring";
      };
      finalCommand = lib.mkOption {
        description = "Final version of command";
        type = nullOr str;
        default = let
          st = cfg.settings;
          prevcmd = st.command;
          command-login-wrapped = [ "loginwrap" ] ++ prevcmd;
          cmd = if (builtins.isNull prevcmd) then null else
            (if st.loginShell then command-login-wrapped else prevcmd);
        in if builtins.isNull cmd then null else lib.escapeShellArgs cmd;
        readOnly = true;
      };
      command = lib.mkOption {
        description = "Command to run following successful authentication";
        type = nullOr (listOf str);
        default = null;
        example = [ "Hyprland" ];
      };

      graphicalInit = lib.mkOption {
        description = "Commands to run upon initialization of a graphical greeter.";
        type = lib.types.lines;
        default = "";
      };

      randr = lib.mkOption {
        description = "Options to pass to wlr-randr";
        type = nullOr (listOf str);
        default = null;
        example = [ "--output" "HDMI-A-3" "--off" ];
      };

      loginShell = lib.mkOption {
        description = "Wrap in login shell to source .profile/.zshenv/etc. (if configurable).";
        type = bool;
        default = true;
        example = false;
      };
      time = lib.mkOption {
        description = "Whether to show the current time (if configurable)";
        type = bool;
        default = true;
        example = false;
      };
      wallpaper = lib.mkOption {
        description = "Path to custom wallpaper (if configurable)";
        type = nullOr path;
        default = "${pkgs.nixfiles-assets}/share/wallpapers/nixfiles-static/Djayjesse-finding_life.png";
        example = "femboy-bee.png";
      };

      autologin = lib.mkOption {
        description = "Whether to configure auto-login";
        type = bool;
        default = false;
        example = true;
      };
      autologinUser = lib.mkOption {
        description = "User to automatically log in";
        type = nullOr str;
        default = null;
        example = "username";
      };
      autolock = lib.mkOption {
        description = ''
          Whether to indicate to a window manager that it should immediately
          lock. This needs to be implemented on a per window manager basis.
        '';
        type = bool;
        default = false;
        example = true;
      };
    };

    presets.regreet.enable = mkPresetOption "regreet";
    presets.tuigreet.enable = mkPresetOption "tuigreet";
  };
}
