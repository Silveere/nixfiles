{
  pkgs,
  lib,
  config,
  osConfig ? {},
  inputs,
  ...
}: let
  cfg = config.nixfiles.packageSets.communication;

  vesktop-ozone-cmd = let
    extraFlags = lib.optionalString config.nixfiles.workarounds.nvidiaPrimary " --disable-gpu";
  in "env NIXOS_OZONE_WL=1 vesktop${extraFlags}";

  waitNet = pkgs.writeShellScript "wait-network" ''
    until ${pkgs.curl}/bin/curl -fs https://www.google.com &>/dev/null; do
      sleep 5
      ((counter++)) && ((counter>=60)) && break
    done
    exec "$@"
  '';
in {
  options.nixfiles.packageSets.communication = {
    enable = lib.mkEnableOption "communication package set";
  };
  config = lib.mkIf cfg.enable {
    xdg.desktopEntries.vesktop = lib.mkIf config.nixfiles.meta.graphical {
      categories = ["Network" "InstantMessaging" "Chat"];
      exec = vesktop-ozone-cmd + " %U";
      genericName = "Internet Messenger";
      icon = "vesktop";
      name = "Vesktop";
      type = "Application";
      settings = {
        StartupWMClass = "Vesktop";
        Keywords = "discord;vencord;electron;chat";
      };
    };

    nixfiles.common.wm.autostart = lib.optionals config.nixfiles.meta.graphical [
      (waitNet + " " + vesktop-ozone-cmd + " --start-minimized")
    ];

    home.packages = with pkgs;
      lib.optionals config.nixfiles.meta.graphical [
        element-desktop
        telegram-desktop
        signal-desktop
        thunderbird
        vesktop
        rustdesk-flutter
        tor-browser
        onionshare
      ]
      ++ [
        irssi
      ];
  };
}
