{ lib, pkgs, osConfig, ... }:
{
  imports = [
    ../../home/common.nix
    # ../../home/hyprland.nix
  ];
  
  home.stateVersion = "23.11";

  wayland.windowManager.hyprland.settings = {
    monitor = ",preferred,auto,1.25";
  };
}
