{ lib, pkgs, config, ... }:
{
  imports = [
    ./desktop-common.nix
  ];

  programs.hyprland = {
    enable = true;
    enableNvidiaPatches = true;
    xwayland.enable = true;
  };

  environment.systemPackages = with pkgs; [
    kitty
    dunst
    polkit-kde-agent
    eww
    hyprpaper
    rofi
    hyprpicker
    udiskie
  ];
}
