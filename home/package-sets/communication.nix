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
    home.packages = with pkgs; lib.optionals config.nixfiles.meta.graphical [
      ( if config.nixfiles.meta.wayland then element-desktop-wayland else element-desktop )
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
