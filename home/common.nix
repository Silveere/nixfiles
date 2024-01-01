{ lib, pkgs, osConfig, ... }:
{
  imports = [
    ./hyprland.nix
  ];

  # home.username = "nullbite";
  # home.homeDirectory = "/home/nullbite";

  home.packages = with pkgs; [
    btop
  ];
}
