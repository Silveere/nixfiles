{ pkgs, lib, config, osConfig ? {}, inputs, ... }:
let
  cfg = config.nixfiles.packageSets.communication;
  rustdesk-pkg = if (lib.strings.hasInfix "23.11" lib.version) then
    inputs.nixpkgs-unstable.legacyPackages.${pkgs.system}.rustdesk-flutter
  else
    pkgs.rustdesk-flutter;
in
{
  options.nixfiles.packageSets.communication = {
    enable = lib.mkEnableOption "communication package set";
  };
  config = lib.mkIf cfg.enable {

    xdg.desktopEntries.vesktop = lib.mkIf config.nixfiles.meta.graphical {
      categories= ["Network" "InstantMessaging" "Chat"];
      # exec="env NIXOS_OZONE_WL=1 vesktop %U";
      exec="vesktop %U";
      genericName="Internet Messenger";
      icon="vesktop";
      name="Vesktop";
      type="Application";
      settings = {
        StartupWMClass="Vesktop";
        Keywords="discord;vencord;electron;chat";
      };
    };

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
