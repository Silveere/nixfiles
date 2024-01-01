{ lib, pkgs, osConfig, ... }:
{
  imports = [
    ../../home/common.nix
  ];
  
  home.stateVersion = "23.11";
}
