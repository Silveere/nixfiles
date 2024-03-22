# This module doesn't configure swaylock on its own (swaylock doesn't have a
# config file), it just produces a "finalCommand" option which can be consumed
# by other functions, and provides a central place to configure it from other
# modules (e.g., to make theming easier). I only want to configure
{ pkgs, config, lib, ... }:
let
  inherit (lib) mkOption;
  inherit (lib.types) nullOr bool int str path;
in
{
  options.nixfiles.helpers.swaylock = {
    wallpaper = lib.mkOption {
      description = "Wallpaper to show on swaylock";
      type = nullOr path;
      default = null;
      example = "femboy-bee.png";
    };
  };
}
