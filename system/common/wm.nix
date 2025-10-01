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

    # this is the proper way to enable things like this where the package may
    # come with a systemd unit but it also probably doesn't warrant its own
    # service option.
    # systemd.packages is very convenient if you just want to enable something
    # with its default config.
    systemd.packages = with pkgs; [
      hyprpolkitagent
    ];

    services.dbus.packages = with pkgs; [
      hyprpolkitagent
    ];

    systemd.user.units."hyprpolkitagent.service".wantedBy = [
      "graphical-session.target"
    ];
  };

  options = {
    nixfiles.common.wm.enable = mkEnableOption "common window manager configuration";
  };
}
