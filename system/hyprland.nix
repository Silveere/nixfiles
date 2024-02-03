{ lib, pkgs, config, ... }:
{
  imports = [
    ./desktop-common.nix
  ];

  services.xserver.displayManager.sddm.enable = true;

  programs.hyprland = {
    enable = true;
    enableNvidiaPatches = true;
    xwayland.enable = true;
  };

  xdg.portal = {
    enable = true;
    extraPortals = [
      pkgs.xdg-desktop-portal-gtk
    ];
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
    polkit-kde-agent
  ];
}
