{
  lib,
  pkgs,
  osConfig,
  ...
}: {
  imports = [
  ];

  config = {
    nixfiles.profile.base.enable = true;

    home.stateVersion = "23.11";

    wayland.windowManager.hyprland.settings = {
      monitor = [
        "HDMI-A-3,disable"
        "Unknown-1,disable"
        "DP-3,highrr,auto,1"
        # this is the "proper" multi monitor config but hyprland's multi
        # monitor system scares me so i am going to keep the other one disabled
        # still. i might need something called hyprsome or something
        # "HDMI-A-3,highrr,0x0,1,transform,1"
        # "DP-3,highrr,1024x160,1"
      ];
    };
  };
}
