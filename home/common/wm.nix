{ pkgs, lib, config, osConfig ? {}, options, ...}:
let
  cfg = config.nixfiles.common.wm;
  inherit (lib) mkDefault;
in
{
  options.nixfiles.common.wm = {
    enable = lib.mkEnableOption "common window manager config";
  };
  config = lib.mkIf cfg.enable {
    # Common options for standalone window managers; many of these (or
    # alternatives thereof) are pulled in by desktop environments.

    qt.enable = true;
    qt.platformTheme = "qtct";
    qt.style.name = "kvantum";

    home.packages = with pkgs; let
      pcmanfm-qt-shim = writeShellScriptBin "pcmanfm" ''
        exec "${pcmanfm-qt}/bin/pcmanfm-qt" "$@"
      '';
    in [
      qt5ct
      qt6ct
      swaybg
      swayidle
      libsForQt5.qtstyleplugin-kvantum

      pcmanfm-qt
      pcmanfm-qt-shim

      wlr-randr
      nwg-look
      nwg-displays

      # very consistent
      (catppuccin-papirus-folders.override {accent = "mauve"; flavor = "mocha"; })
      (pkgs.catppuccin-kvantum.override {accent = "Mauve"; variant = "Mocha"; })
      catppuccin-cursors.mochaMauve

      arc-theme
    ];

    programs = {
      swaylock = {
        enable = true;
        package = pkgs.swaylock-effects;
      };
    };
    services = {
      udiskie = {
        enable = mkDefault true;
        automount = mkDefault false;
      };
    };
  };
}
