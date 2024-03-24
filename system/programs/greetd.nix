{ pkgs, config, lib, options, ... }:
let
  cfg = config.nixfiles.programs.greetd;
  inherit (lib.types) bool enum nullOr str path listOf;
  inherit (builtins) isNull;
  inherit (lib) optional optionals;
  optionalsSet = val: optionals (!(isNull val));
  optionalSet = val: optional (!(isNull val));
  sessions = config.services.xserver.displayManager.sessionData.desktops;
  xsessions = "${sessions}/share/xsessions";
  wayland-sessions = "${sessions}/share/wayland-sessions";

  loginwrap=pkgs.writeShellScriptBin "loginwrap" ''
    exec "$SHELL" -lc 'exec "$@"' "login-wrapper" "$@"
  '';
in
{
  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ loginwrap ];
    services.greetd = {
      enable = true;
      settings = {
        default_session = lib.mkMerge [

          # tuigreet configuration
          (lib.mkIf cfg.presets.tuigreet.enable {
            command = let
              st = cfg.settings;
              args = [ "${pkgs.greetd.tuigreet}/bin/tuigreet" "--asterisks" "--remember" "--remember-session"
              "--sessions" "${xsessions}:${wayland-sessions}" ]
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
    nixfiles.programs.greetd.presets.${cfg.preset}.enable = true;
  };

  options.nixfiles.programs.greetd = {
    enable = lib.mkEnableOption "greetd configuration";

    preset = lib.mkOption {
      description = "greetd configuration to enable (shorthand for presets.<preset>.enable)";
      type = enum (lib.mapAttrsToList (name: value: name) options.nixfiles.programs.greetd.presets);
      default = "tuigreet";
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
        in lib.escapeShellArgs cmd;
        readOnly = true;
      };
      command = lib.mkOption {
        description = "Command to run following successful authentication";
        type = nullOr (listOf str);
        default = null;
        example = [ "Hyprland" ];
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
    };
    presets.tuigreet.enable = lib.mkOption {
      description = "tuigreet greetd configuration";
      type = bool;
      default = false;
    };
  };
}
