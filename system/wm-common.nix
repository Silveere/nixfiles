{ pkgs, lib, config, options, ...}:
let
  inherit (lib) mkDefault mkIf mkEnableOption;
  cfg = config.nixfiles.common.window-manager;
in
{
  config = mkIf cfg.enable {
    # Common options for standalone window managers; many of these (or
    # alternatives thereof) are pulled in by desktop environments.
    services = {
      power-profiles-daemon.enable = mkDefault true;
      blueman.enable = mkDefault config.hardware.bluetooth.enable;
    };
    programs = {
      nm-applet.enable = mkDefault config.networking.networkmanager.enable;
    };
  };
  options = {
    nixfiles.common.window-manager.enable = mkEnableOption "common window manager configuration";
  };
}
