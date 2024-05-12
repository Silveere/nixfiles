{ lib, pkgs, osConfig, config, ... }:
{
  imports = [
    ../../home
  ];

  config = {
    nixfiles = {
      profile.base.enable = true;

      common.wm.keybinds.Launch1="playerctl play-pause";
    };
    home.stateVersion = "23.11";

    wayland.windowManager.hyprland.settings = {
      monitor = ",preferred,auto,1.25";
    };
  };
}
