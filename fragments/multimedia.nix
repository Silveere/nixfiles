{ config, lib, pkgs, ...}:
{
  environment.systemPackages = with pkgs; [
    mpv
    gimp-with-plugins
  ];
}
