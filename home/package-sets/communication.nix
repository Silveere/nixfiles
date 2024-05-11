{ pkgs, lib, config, osConfig ? {}, inputs, ... }:
let
  cfg = config.nixfiles.packageSets.communication;
  rustdesk-pkg = if (lib.strings.hasInfix "23.11" lib.version) then
    inputs.nixpkgs-unstable.legacyPackages.${pkgs.system}.rustdesk-flutter
  else
    pkgs.rustdesk-flutter;

  vesktop-ozone-cmd = "env NIXOS_OZONE_WL=1 vesktop --disable-gpu";
in
{
  options.nixfiles.packageSets.communication = {
    enable = lib.mkEnableOption "communication package set";
  };
  config = lib.mkIf cfg.enable {

    xdg.desktopEntries.vesktop = lib.mkIf config.nixfiles.meta.graphical {
      categories= ["Network" "InstantMessaging" "Chat"];
      exec=vesktop-ozone-cmd + " %U";
      genericName="Internet Messenger";
      icon="vesktop";
      name="Vesktop";
      type="Application";
      settings = {
        StartupWMClass="Vesktop";
        Keywords="discord;vencord;electron;chat";
      };
    };

    nixfiles.common.wm.autostart = lib.optionals config.nixfiles.meta.graphical [
      (vesktop-ozone-cmd + " --start-minimized")
    ];

    home.packages = with pkgs; lib.optionals config.nixfiles.meta.graphical [
      element-desktop
      telegram-desktop
      signal-desktop
      thunderbird
      vesktop
      rustdesk-pkg
    ] ++ [
      irssi
    ];
  };
}
