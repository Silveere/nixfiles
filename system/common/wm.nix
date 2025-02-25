{
  pkgs,
  lib,
  config,
  options,
  ...
}: let
  inherit (lib) mkDefault mkIf mkEnableOption;
  cfg = config.nixfiles.common.wm;
in {
  config = mkIf cfg.enable {
    # Common options for standalone window managers; many of these (or
    # alternatives thereof) are pulled in by desktop environments.
    services = {
      power-profiles-daemon.enable = mkDefault true;
      blueman.enable = mkDefault config.hardware.bluetooth.enable;
      udisks2.enable = mkDefault true;
    };
    programs = {
      nm-applet.enable = mkDefault config.networking.networkmanager.enable;
    };
    security.pam.services.swaylock = {};
  };
  options = {
    nixfiles.common.wm.enable = mkEnableOption "common window manager configuration";
  };
}
