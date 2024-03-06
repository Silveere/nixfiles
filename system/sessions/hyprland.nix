{ lib, pkgs, config, inputs, ... }:
let
  cfg = config.nixfiles.sessions.hyprland;
  flake-package = inputs.hyprland.packages.${pkgs.system}.hyprland;
in
{
  # imports = [
  #   ./desktop-common.nix
  #   # FIXME make this into an option
  #   ./wm-common.nix
  # ];

  options.nixfiles.sessions.hyprland = {
    enable = lib.mkEnableOption "hyprland configuration";
    useFlake = lib.mkEnableOption "hyprland flake package";
  };

  config = lib.mkIf cfg.enable {
    # enable dependencies
    nixfiles.common = {
      desktop.enable = true;
      wm.enable = true;
    };
    nixfiles.meta.wayland = true;

    services.xserver.displayManager.sddm = {
      enable = lib.mkDefault true;
      wayland.enable = true;
    };

    programs.hyprland = {
      enable = true;
      # # TODO base this on if nvidia is enabled
      # enableNvidiaPatches = lib.mkIf (!cfg.useFlake) lib.mkDefault true;
      xwayland.enable = true;
      package = lib.mkIf cfg.useFlake flake-package;
    };

    environment.variables = lib.mkMerge [
      {
        # NIXOS_OZONE_WL = "1"; # this is breaking things for some reason
      }

      (lib.mkIf config.hardware.nvidia.modesetting.enable {
        WLR_NO_HARDWARE_CURSORS = "1";
      })
    ];

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
