{ config, lib, pkgs, ...}:
{
  # oopsies this is for home-manager
  # programs.mangohud.enable = lib.mkDefault true;

  programs.steam = {
    enable = lib.mkDefault true;
    gamescopeSession = {
      enable = lib.mkDefault true;
    };
  };

  programs.gamemode = {
    enable = lib.mkDefault true;
    enableRenice = lib.mkDefault true;
  };

  programs.gamescope = {
    enable = lib.mkDefault true;
    capSysNice = lib.mkDefault false;
  };

  environment.systemPackages = with pkgs; [
    mangohud
    goverlay
    prismlauncher
  ];
}
