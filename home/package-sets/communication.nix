{ pkgs, lib, config, osConfig ? {}, ... }:
let
  cfg = config.nixfiles.packageSets.communication;
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
    ] ++ [
      irssi
    ];
  };
}
