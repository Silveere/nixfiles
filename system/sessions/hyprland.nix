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
    useFlake = lib.mkOption {
      description = "Whether to use the Hyprland flake package";
      type = lib.types.bool;
      # enable if not on nixpkgs stable
      # defaultText = "config.nixfiles.nixpkgs != inputs.nixpkgs";
      default = true;
      example = false;
    };
  };

  config = lib.mkIf cfg.enable {
    # enable dependencies
    nixfiles.common = {
      desktop.enable = true;
      wm.enable = true;
    };
    nixfiles.meta.wayland = true;

    # greeter
    nixfiles.programs.greetd = {
      enable = true;
      settings = {
        command = [ "${config.programs.hyprland.finalPackage}/bin/Hyprland" ];
      };
    };

    programs.hyprland = {
      enable = true;
      # # TODO base this on if nvidia is enabled
      # enableNvidiaPatches = lib.mkIf (!cfg.useFlake) lib.mkDefault true;
      xwayland.enable = true;
      package = lib.mkIf cfg.useFlake flake-package;
    };

    hardware.opengl = let
      hyprland-pkgs = inputs.hyprland.inputs.nixpkgs.legacyPackages.${pkgs.system};
      hyprlandMesa = hyprland-pkgs.mesa.drivers;
      hyprlandMesa32 = hyprland-pkgs.pkgsi686Linux.mesa.drivers;
      useHyprlandMesa = cfg.useFlake && (config.nixfiles.nixpkgs == inputs.nixpkgs);
    in lib.mkIf useHyprlandMesa {
      package = hyprlandMesa;
      package32 = hyprlandMesa32;
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
