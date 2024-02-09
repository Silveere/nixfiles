{ lib, pkgs, osConfig, ... }:
{
  imports = [
  ];

  config = {
    nixfiles.profile.base.enable = true;
    
    home.stateVersion = "23.11";
  };
}
