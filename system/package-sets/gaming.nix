{ config, lib, pkgs, ...}:
let
  cfg = config.nixfiles.packageSets.gaming;
in
{
  # oopsies this is for home-manager
  # programs.mangohud.enable = lib.mkDefault true;

  options.nixfiles.packageSets.gaming = {
    enable = lib.mkEnableOption "gaming package set";
  };
  config = lib.mkIf cfg.enable {
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
      glxinfo
      vulkan-tools
      legendary-gl
      heroic
    ];
  };
}
