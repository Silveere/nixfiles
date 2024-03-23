{ pkgs, config, lib, inputs, nixpkgs, ... }:
let
  p5 = config.services.xserver.desktopManager.plasma5.enable;
  p6 = config.services.desktopManager.plasma6.enable;
in
{
  config = lib.mkMerge [
  ];
}
