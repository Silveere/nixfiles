{ lib, pkgs, osConfig, config, ... }:
{
  imports = [
    ../../home
  ];

  config = {
    nixfiles = {
      profile.base.enable = true;
    };
    home.stateVersion = "23.11";

    wayland.windowManager.hyprland.settings = {
      monitor = ",preferred,auto,1.25";
    };
  };
}
