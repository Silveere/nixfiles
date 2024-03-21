{ pkgs, config, lib, options, ... }:
let
  cfg = config.nixfiles.programs.greetd;
  inherit (lib.types) bool enum nullOr str path;
  inherit (builtins) isNull;
  inherit (lib) optional optionals;
  optionalsSet = val: optionals (!(isNull val));
  sessions = config.services.xserver.displayManager.sessionData.desktops;
  xsessions = "${sessions}/share/xsessions";
  wayland-sessions = "${sessions}/share/wayland-sessions";
in
{
  config = lib.mkIf cfg.enable {
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
                ++ optionalsSet st.command [ "--cmd" (lib.escapeShellArg st.command) ];
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
      command = lib.mkOption {
        description = "Command to run following successful authentication";
        type = nullOr str;
        default = null;
        example = "Hyprland";
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
