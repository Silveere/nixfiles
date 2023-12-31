{ lib, pkgs, osConfig, ... }:
{

  # home.username = "nullbite";
  # home.homeDirectory = "/home/nullbite";

  home.packages = with pkgs; [
    btop
  ];

  home.stateVersion = "23.11";
}
