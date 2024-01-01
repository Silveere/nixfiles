{ config, lib, pkgs, ...}:
{
  imports = [ ./cli-multimedia.nix ];
  environment.systemPackages = with pkgs; [
    mpv
    gimp-with-plugins
  ];
}
