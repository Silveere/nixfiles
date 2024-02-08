{ config, lib, pkgs, ...}:
let
  cfg = config.nixfiles.packageSets.multimedia;
  inherit (lib) optionals mkEnableOption mkIf;
in
{
  options.nixfiles.packageSets.multimedia = {
    enable = mkEnableOption "multimedia packages";
  };
  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; optionals config.services.xserver.enable [
      mpv
      gimp-with-plugins
      krita
      inkscape
    ] ++ [
      yt-dlp
      imagemagick
      ffmpeg
    ];
  };
}
