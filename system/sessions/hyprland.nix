{ lib, pkgs, config, ... }:
let
  cfg = config.nixfiles.sessions.hyprland;
in
{
  # imports = [
  #   ./desktop-common.nix
  #   # FIXME make this into an option
  #   ./wm-common.nix
  # ];

  options.nixfiles.sessions.hyprland = {
    enable = lib.mkEnableOption "hyprland configuration";
  };

  config = lib.mkIf cfg.enable {
    # enable dependencies
    nixfiles.common = {
      desktop.enable = true;
      wm.enable = true;
    };
    nixfiles.meta.wayland = true;

    services.xserver.displayManager.sddm.enable = true;

    programs.hyprland = {
      enable = true;
      # TODO base this on if nvidia is enabled
      enableNvidiaPatches = lib.mkDefault true;
      xwayland.enable = true;
    };

    xdg.portal = {
      enable = true;
      extraPortals = [
        pkgs.xdg-desktop-portal-gtk
      ];
    };

    environment.systemPackages = with pkgs; [
      kitty
        dunst
        polkit-kde-agent
        eww
        hyprpaper
        rofi
        hyprpicker
        udiskie
        polkit-kde-agent
    ];
  };
}
