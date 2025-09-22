{
  config,
  lib,
  pkgs,
  inputs,
  ...
}: let
  cfg = config.nixfiles.packageSets.gaming;
in {
  # oopsies this is for home-manager
  # programs.mangohud.enable = lib.mkDefault true;

  options.nixfiles.packageSets.gaming = {
    enable = lib.mkEnableOption "gaming package set";
  };
  config = lib.mkIf cfg.enable {
    nixpkgs.overlays = let
      steamGamescopeFix = final: prev: {
        steam = prev.steam.override {
          extraPkgs = pkgs:
            with pkgs; [
              xorg.libXcursor
              xorg.libXi
              xorg.libXinerama
              xorg.libXScrnSaver
              SDL2
              libpng
              libpulseaudio
              libvorbis
              stdenv.cc.cc.lib
              libkrb5
              keyutils
            ];
        };
      };
    in [steamGamescopeFix];

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

    virtualisation.waydroid.enable = lib.mkDefault true;

    environment.systemPackages = with pkgs; [
      protontricks
      mangohud
      goverlay
      prismlauncher
      glxinfo
      vulkan-tools
      legendary-gl
      heroic
      protonup-ng
      protonup-qt
      lucem
      steamtinkerlaunch
    ];
  };
}
