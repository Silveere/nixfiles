{ config, lib, pkgs, ... }:
let
  cfg = config.nixfiles.theming;

  toCaps = s: with lib.strings; with builtins;
    (toUpper (substring 0 1 s)) + toLower (substring 1 ((stringLength s)-1) s);
  inherit (lib.strings) toUpper toLower;

  mkCtp = flavor: accent: with pkgs; {
    names = {
      cursors = "Catppuccin-${toCaps flavor}-${toCaps accent}-Cursors";
      icons = "Papirus-Dark";
      gtk = let
        base = "Catppuccin-${toCaps flavor}-Standard-${toCaps accent}-Dark";
      in {
        normal = "${base}";
        hdpi = "${base}-hdpi";
        xhdpi = "${base}-xhdpi";
      };
    };
    packages = {
      cursors = catppuccin-cursors."${toLower flavor}${toCaps accent}";
      kvantum = catppuccin-kvantum.override { variant = toCaps flavor; accent = toCaps accent; };
      icons = catppuccin-papirus-folders.override { flavor = toLower flavor; accent = toLower accent; };
      gtk = catppuccin-gtk.override { variant = toLower flavor; accents = [ (toLower accent) ]; };
    };
  };

  ctp = with cfg.catppuccin; mkCtp flavor accent;
in {
  options.nixfiles.theming = { 
    enable = lib.mkEnableOption "nixfiles theming options";

    catppuccin = {
      themeDPI = lib.mkOption {
        description = "Catppuccin theme DPI preset";
        type = with lib.types; oneOf (mapAttrsToList (k: v: k) ctp.names.gtk);
        default = "normal";
      };
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
    fonts.fontconfig.enable = lib.mkDefault true;

    home.packages = with pkgs; [
      ubuntu_font_family
    ] ++ lib.mapAttrsToList (k: v: v) ctp.packages;

    gtk = {
      enable = true;
      font = lib.mkIf (!(config.stylix.enable)) (lib.mkDefault {
        name = "Ubuntu";
        package = pkgs.ubuntu_font_family;
        size = lib.mkDefault 12;
      });

      theme = lib.mkDefault {
        package = ctp.packages.gtk;
        name = ctp.names.gtk.normal;
      };

      iconTheme = lib.mkDefault {
        name = ctp.names.icons;
        package = ctp.packages.icons;
      };
    };

    stylix = {
      enable = true;
      autoEnable = true;
      cursor = {
        package = lib.mkDefault ctp.packages.cursors;
        name = lib.mkDefault ctp.names.cursors;
        size = lib.mkDefault 24;
        # x11.enable = lib.mkDefault true;
        # gtk.enable = lib.mkDefault true;
      };

      fonts = let
        ubuntu = pkgs.ubuntu_font_family;
      in {
        # packages = with pkgs; [
        #   ubuntu_font_family
        #   noto-fonts-emoji-blob-bin
        # ];
        emoji = {
          package = pkgs.noto-fonts-emoji-blob-bin;
          name = "Blobmoji";
        };
        monospace = {
          package = ubuntu;
          name = "Ubuntu Mono";
        };
        sansSerif = {
          package = ubuntu;
          name = "Ubuntu";
        };

        sizes = {
          applications = 13;
          desktop = 13;
          popups = 13;
          terminal = 13;
        };
      };
    };
  };
}
