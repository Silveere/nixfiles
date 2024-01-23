{ lib, pkgs, osConfig, ... }:
{
  imports = [
    ./comma.nix
  ];
  # home.username = "nullbite";
  # home.homeDirectory = "/home/nullbite";

  home.packages = with pkgs; [
    btop
  ];
}
