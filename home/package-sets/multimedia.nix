{ config, lib, pkgs, inputs, osConfig ? { }, ...}:
let
  cfg = config.nixfiles.packageSets.multimedia;
  inherit (lib) optionals mkEnableOption mkIf;
  default = osConfig ? nixfiles && osConfig.nixfiles.packageSets.multimedia.enable;
  mkOverrideEach = pri: lib.mapAttrs (_:v: lib.mkOverride pri v);
in
{
  options.nixfiles.packageSets.multimedia = {
    enable = lib.mkOption {
      description = "Whether to enable multimedia packages";
      type = lib.types.bool;
      example = true;
      inherit default;
    };
  };

  config = mkIf cfg.enable {
    assertions = [ { assertion = inputs.nixpkgs-unstable.sourceInfo.lastModified <= 1720571246; message = "re-add picard and remove this assertion"; } ];

    home.packages = with pkgs; optionals config.nixfiles.meta.graphical [
      mpv
      gimp
      krita
      inkscape
      obs-studio
      nomacs
      audacity
      # picard
      spicetify-cli
    ] ++ [
      yt-dlp
      gallery-dl
      imagemagick
      pngquant
      ffmpeg
      gifski
    ];

    xdg.mimeApps.defaultApplications = lib.mkMerge [
      # project files
      (mkOverrideEach 100 {
        "image/x-xcf" = [ "gimp.desktop" ];
        "image/x-compressed-xcf" = [ "gimp.desktop" ];
        "image/x-krita" = [ "krita.desktop" ];
        "application/x-audacity-project" = [ "audacity.desktop" ];
        "application/x-audacity-project+sqlite3" = [ "audacity.desktop" ];
        "image/svg+xml" = [ "org.inkscape.Inkscape.desktop" ];
        "image/svg+xml-compressed" = [ "org.inkscape.Inkscape.desktop" ];
      })
      # general files
      (with pkgs; mkOverrideEach 150 (config.lib.xdg.mimeAssociations [ nomacs mpv ]))
      # rest of the files
      (with pkgs; mkOverrideEach 200 (config.lib.xdg.mimeAssociations [ inkscape gimp audacity ]))
    ];
  };
}
