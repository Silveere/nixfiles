{ pkgs, lib, config, osConfig ? {}, ... }:
let
  cfg = config.nixfiles.packageSets.communication;
in
{
  options.nixfiles.packageSets.communication = {
    enable = lib.mkEnableOption "communication package set";
  };
  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; lib.optionals config.nixfiles.graphical [
      element-desktop-wayland
      telegram-desktop
      signal-desktop
      thunderbird
    ] ++ [
      irssi
    ];
  };
}
