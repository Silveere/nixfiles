{ config, lib, pkgs, ...}:
let
  cfg = config.nixfiles.packageSets.multimedia;
  inherit (lib) optional optionals mkEnableOption mkIf;
  nvidiaEnabled = (lib.elem "nvidia" config.services.xserver.videoDrivers);
in
{
  options.nixfiles.packageSets.multimedia = {
    enable = mkEnableOption "multimedia packages";
  };
  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; optionals config.services.xserver.enable [
      mpv
      gimp
      krita
      inkscape
      obs-studio
    ] ++ [
      gallery-dl
      yt-dlp
      imagemagick
      pngquant
      gifski
      ffmpeg
    ];

    # needed for NVENC to work in OBS Studio and FFmpeg
    boot.kernelModules = optional nvidiaEnabled "nvidia_uvm";
  };
}
