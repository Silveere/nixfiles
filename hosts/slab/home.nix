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

    # auto start Hyprland on tty1
    programs.zsh.initExtraFirst = let
      hyprland="${config.wayland.windowManager.hyprland.finalPackage}/bin/Hyprland";
      tty="${pkgs.coreutils}/bin/tty";
    in lib.mkIf config.wayland.windowManager.hyprland.enable ''
        if [[ "$(${tty})" == "/dev/tty1" && -z "''${WAYLAND_DISPLAY:+x}" ]] ; then
          ${hyprland}
        fi
      '';

    wayland.windowManager.hyprland.settings = {
      monitor = ",preferred,auto,1.25";
    };
  };
}
