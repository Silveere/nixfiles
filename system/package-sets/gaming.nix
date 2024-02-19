{ config, lib, pkgs, inputs, ...}:
let
  cfg = config.nixfiles.packageSets.gaming;
  is2311 = lib.strings.hasInfix "23.11" lib.version;
in
{
  # oopsies this is for home-manager
  # programs.mangohud.enable = lib.mkDefault true;

  options.nixfiles.packageSets.gaming = {
    enable = lib.mkEnableOption "gaming package set";
  };
  config = lib.mkIf cfg.enable {

                                  # only needed on 23.11, increases closure size MASSIVELY
    nixpkgs.overlays = lib.optional is2311 (_: _: {
      # unstable steam has new buildFSHEnv which doesn't break on rebuild
      steam = (import inputs.nixpkgs-unstable.outPath {config.allowUnfree = true; inherit (pkgs) system; }).steam;
    });

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
      mangohud
      goverlay
      prismlauncher
      glxinfo
      vulkan-tools
      legendary-gl
      heroic
      protonup-ng
      protonup-qt
    ];
  };
}
