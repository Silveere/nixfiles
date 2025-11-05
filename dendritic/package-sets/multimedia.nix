{config, lib, ...}: let
  inherit (builtins) concatLists;
  inherit (lib.lists) unique;

  mpvScripts = pkgs: (mkPackageLists pkgs).mpvScripts;

  mkPackageLists = pkgs: rec {
    graphical-common = with pkgs; [
      gimp3
      krita
      inkscape
      obs-studio
      nomacs
      audacity
      picard
      spicetify-cli # yes this is cli but it is useless on a non graphical system
      feishin
      (kodi.withPackages (_: [])) # this is required to get python libs
    ];

    graphical-home = graphical-common;
    graphical-system = graphical-common;

    cli-common = with pkgs; [
      yt-dlp
      gallery-dl
      tidal-dl
      imagemagick
      pngquant
      ffmpeg
      gifski
      beets
    ];

    cli-system =
      let
        mpv-with-scripts = pkgs.mpv-unwrapped.wrapper {
          mpv = pkgs.mpv-unwrapped;
          scripts = mpvScripts;
        };
      in cli-common ++ [
        mpv-with-scripts
      ];
    cli-home = cli-common;

    mpvScripts = with pkgs.mpvScripts; [
      videoclip
    ];
  };

  homeModule = {
    config,
    lib,
    pkgs,
    osConfig ? {},
    ...
  }: let
    packageLists = mkPackageLists pkgs;
    cfg = config.nixfiles.packageSets.multimedia;
    inherit (lib) optionals mkEnableOption mkIf;
    default = (osConfig ? nixfiles) && osConfig.nixfiles.packageSets.multimedia.enable && config.nixfiles.useOsConfig;
    mkOverrideEach = pri: lib.mapAttrs (_: v: lib.mkOverride pri v);
  in {
    options.nixfiles.packageSets.multimedia = {
      enable = lib.mkOption {
        description = "Whether to enable multimedia packages";
        type = lib.types.bool;
        example = true;
        inherit default;
      };
    };

    config = mkIf cfg.enable {
      programs.mpv = {
        enable = lib.mkDefault true;
        scripts = packageLists.mpvScripts;
      };

      home.packages =
        optionals config.nixfiles.meta.graphical packageLists.graphical-home
        ++ packageLists.cli-home;

      xdg.mimeApps.defaultApplications = lib.mkMerge [
        # project files
        (mkOverrideEach 100 {
          "image/x-xcf" = ["gimp.desktop"];
          "image/x-compressed-xcf" = ["gimp.desktop"];
          "image/x-krita" = ["krita.desktop"];
          "application/x-audacity-project" = ["audacity.desktop"];
          "application/x-audacity-project+sqlite3" = ["audacity.desktop"];
          "image/svg+xml" = ["org.inkscape.Inkscape.desktop"];
          "image/svg+xml-compressed" = ["org.inkscape.Inkscape.desktop"];
        })
        # general files
        (with pkgs; mkOverrideEach 150 (config.lib.xdg.mimeAssociations [nomacs mpv]))
        # rest of the files
        (with pkgs; mkOverrideEach 200 (config.lib.xdg.mimeAssociations [inkscape gimp3 audacity]))
      ];
    };
  };

  nixosModule = {
    config,
    lib,
    pkgs,
    ...
  }: let
    packageLists = mkPackageLists pkgs;
    cfg = config.nixfiles.packageSets.multimedia;
    inherit (lib) optional optionals mkEnableOption mkIf;
    nvidiaEnabled = lib.elem "nvidia" config.services.xserver.videoDrivers;
  in {
    options.nixfiles.packageSets.multimedia = {
      enable = mkEnableOption "multimedia packages";
    };
    config = mkIf cfg.enable {
      environment.systemPackages =
        optionals config.services.xserver.enable packageLists.graphical-system
        ++ packageLists.cli-system;

      # needed for NVENC to work in OBS Studio and FFmpeg
      boot.kernelModules = optional nvidiaEnabled "nvidia_uvm";

      # V4L2 loopback for OBS webcam
      boot.extraModulePackages = with config.boot.kernelPackages; [
        v4l2loopback
      ];
    };
  };
in {
  config.flake.modules.nixos.nixfiles = nixosModule;
  config.flake.modules.homeManager.nixfiles = homeModule;
}
