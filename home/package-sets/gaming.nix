{ config, osConfig ? { }, lib, pkgs, ... }:
let
  cfg = config.nixfiles.packageSets.gaming;
  default = osConfig.nixfiles.packageSets.gaming.enable or false;
in
{
  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      ludusavi
      rclone # needed to sync ludusavi
      protontricks
    ] ++ lib.optionals cfg.enableLaunchers [
      steam
      prismlauncher
      heroic
      legendary-gl
    ];
  };
  options.nixfiles.packageSets.gaming = {
    enable = lib.mkOption {
      description = "Whether to install gaming-related packages";
      inherit default;
      type = lib.types.bool;
      example = true;
    };
    enableLaunchers = lib.mkOption {
      description = ''
        Whether to install launchers as user-level config. This is left
        disabled by default as to not conflict with any game launchers provided
        by the user's distribution (for example, installing another Steam on
        the Steam Deck seems like an absolutely AWFUL idea). Nix (on non-NixOS)
        also has not-so-great handling of OpenGL, so launchers should probably
        be installed via the user's distribution instead.
      '';
      type = lib.types.bool;
      default = false;
      example = true;
    };
  };
}
