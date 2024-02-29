{ config, lib, pkgs, osConfig ? { }, ...}:
let
  cfg = config.nixfiles.packageSets.multimedia;
  inherit (lib) optionals mkEnableOption mkIf;
  default = osConfig ? nixfiles && osConfig.nixfiles.packageSets.multimedia.enable;
in
{
  options.nixfiles.packageSets.multimedia = {
    enable = lib.mkOption {
      description = "Whether to enable multimedia packages";
      type = lib.types.bool;
      example = true;
      inherit default;
    };
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; optionals config.nixfiles.meta.graphical [
      mpv
      gimp-with-plugins
      krita
      inkscape
      obs-studio
    ] ++ [
      yt-dlp
      imagemagick
      ffmpeg
    ];
  };
}
