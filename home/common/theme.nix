{ config, lib, pkgs, ... }:
let
  cfg = config.nixfiles.theming;

  mkCtpPackages = flavor: accent: let
    toCaps = s: with lib.strings; with builtins;
      (toUpper (substring 0 1 s)) + toLower (substring 1 ((stringLength s)-1) s);
    inherit (lib.strings) toUpper toLower;
  in with pkgs; {
    cursors = catppuccin-cursors."${toLower flavor}${toCaps accent}";
    cursorName = "Catppuccin-${toCaps flavor}-${toCaps accent}-Cursors";
    kvantum = catppuccin-kvantum.override { variant = toCaps flavor; accent = toCaps accent; };
    icons = catppuccin-papirus-folders.override { flavor = toLower flavor; accent = toLower accent; };
  };

  ctpPackages = with cfg.catppuccin; mkCtpPackages flavor accent;
in {
  options.nixfiles.theming = { 
    enable = lib.mkEnableOption "nixfiles theming options";
    catppuccin = {
      flavor = lib.mkOption {
        description = "Catppuccin flavor";
        type = lib.types.str;
        default = "mocha";
      };
      accent = lib.mkOption {
        description = "Catppuccin accent";
        type = lib.types.str;
        default = "mauve";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    gtk.enable = true;

    home.pointerCursor = {
      package = lib.mkDefault ctpPackages.cursors;
      name = lib.mkDefault ctpPackages.cursorName;
      size = lib.mkDefault 24;
      x11.enable = lib.mkDefault true;
      gtk.enable = lib.mkDefault true;
    };
  };
}
