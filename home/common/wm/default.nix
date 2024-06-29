{ pkgs, lib, config, osConfig ? {}, options, ...}:
let
  cfg = config.nixfiles.common.wm;
  inherit (lib) mkDefault;
  mkOverrideEach = pri: lib.mapAttrs (_:v: lib.mkOverride pri v);
in
{
  options.nixfiles.common.wm = {
    enable = lib.mkEnableOption "common window manager config";
    autostart = lib.mkOption {
      description = "List of window manager agnostic commnads to run at window manager startup";
      type = lib.types.listOf lib.types.str;
      default = [ ];
      example = [ "steam -silent" ];
    };
  };

  imports = [
    ./keybinds.nix
  ];
  config = lib.mkIf cfg.enable {
    # Common options for standalone window managers; many of these (or
    # alternatives thereof) are pulled in by desktop environments.

    nixfiles.theming.enable = lib.mkDefault true;
    nixfiles.programs.dunst.enable = lib.mkDefault true;

    qt.enable = true;
    qt.platformTheme.name = "qtct";
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

      playerctl

      pcmanfm
      ffmpegthumbnailer

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
      waybar = {
        enable = true;
      };

      swaylock = {
        enable = true;
        package = pkgs.swaylock-effects;
        settings = {
          image = "${pkgs.nixfiles-assets}/share/wallpapers/nixfiles-static/Djayjesse-finding_life.png";
          scaling = "fill";
        };
      };
    };


    # File associations
    xdg.mimeApps = {
      enable = true;
      defaultApplications = let
        defaultBrowser = [ "firefox.desktop" ];
      in mkOverrideEach 50 {
        "x-scheme-handler/https" = defaultBrowser;
        "x-scheme-handler/http" = defaultBrowser;
        "text/html" = defaultBrowser;
        "application/xhtml+xml" = defaultBrowser;
        "application/pdf" = defaultBrowser;
      };
    };
    # this makes xdg.mimeApps overwrite mimeapps.list if it has been touched by something else
    xdg.configFile."mimeapps.list" = {
      force = true;
    };

    services = {
      playerctld.enable = mkDefault true;

      udiskie = {
        enable = mkDefault true;
        automount = mkDefault false;
      };
    };
  };
}
