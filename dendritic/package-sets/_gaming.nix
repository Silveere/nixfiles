# TODO this isn't done yet
{...}: let
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

  nixosModule = {
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
      nixpkgs.overlays = [steamGamescopeFix];

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
        mesa-demos
        vulkan-tools
        legendary-gl
        heroic
        protonup-ng
        protonup-qt
        lucem
        steamtinkerlaunch
      ];
    };
  };

  homeModule = {
    config,
    osConfig ? {},
    lib,
    pkgs,
    ...
  }: let
    cfg = config.nixfiles.packageSets.gaming;
    default = (osConfig.nixfiles.packageSets.gaming.enable or false) && config.nixfiles.useOsConfig;
  in {
    config = lib.mkIf cfg.enable {
      nixpkgs.overlays = let
      in
        lib.mkAfter [];

      nixfiles.common.wm.autostart = [
        "steam -silent"
      ];

      # gamescope fix
      xdg.configFile."gamescope/scripts/10-esync-disable.lua" = {
        source = ./gamescope-esync-disable.lua;
      };

      home.packages = with pkgs;
        [
          ludusavi
          rclone # needed to sync ludusavi
          protontricks
          steamtinkerlaunch
        ]
        ++ lib.optionals cfg.enableLaunchers [
          steam
          prismlauncher
          heroic
          legendary-gl
          lucem
        ];
    };
    options.nixfiles.packageSets.gaming = {
      enable = lib.mkOption {
        description = "Whether to install gaming-related packages";
        inherit default;
        type = lib.types.bool;
        example = true;
      };
      enableLaunchers = lib.mkOption {
        description = ''
          Whether to install launchers as user-level config. This is left
          disabled by default as to not conflict with any game launchers provided
          by the user's distribution (for example, installing another Steam on
          the Steam Deck seems like an absolutely AWFUL idea). Nix (on non-NixOS)
          also has not-so-great handling of OpenGL, so launchers should probably
          be installed via the user's distribution instead.
        '';
        type = lib.types.bool;
        default = false;
        example = true;
      };
    };
  };
in {
  config = {
    flake.modules = {
      nixos.nixfiles = nixosModule;
      homeManager.nixfiles = homeModule;
    };
  };
}
