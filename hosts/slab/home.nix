{
  lib,
  pkgs,
  osConfig,
  config,
  ...
}: {
  imports = [
    ../../home
  ];

  config = {
    nixfiles = {
      profile.base.enable = true;

      common.wm.keybinds = {
        Launch1 = "playerctl play-pause"; # ROG key
        # Launch3="true"; # AURA fn key
        # Launch4="true"; # fan control fn key
      };
    };
    home.stateVersion = "23.11";

    # TODO mkif stylix.enable; danth/stylix#216
    home.pointerCursor = lib.mkIf (config.nixfiles.theming.enable && !config.stylix.enable) {size = 32;};
    stylix.cursor = lib.mkIf config.stylix.enable {size = 32;};

    nixfiles.theming.catppuccin.themeDPI = "hdpi";

    wayland.windowManager.hyprland.settings = {
      monitor = ",preferred,auto,1.25";
    };
  };
}
