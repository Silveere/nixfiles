{ lib, pkgs, osConfig, ... }:
{
  imports = [
  ];

  config = {
    nixfiles.profile.base.enable = true;

    home.stateVersion = "23.11";

    wayland.windowManager.hyprland.settings = {
      monitor = [
        "HDMI-A-3,disable"
        "DP-3,highrr,auto,1"
      ];
    };
  };
}
