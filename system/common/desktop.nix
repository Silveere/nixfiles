{ config, lib, pkgs, outputs, ...}:
let
  cfg = config.nixfiles.common.desktop;
  inherit (lib) mkIf mkDefault mkForce mkEnableOption;
in
{
  # imports = [
  #   ./base.nix
  #   ./fragments/sound.nix
  #   ./fragments/multimedia.nix
  #   ./fragments/software/syncthing.nix
  #   ./fragments/hardware/bluetooth.nix
  # ];

  options.nixfiles.common.desktop = {
    enable = mkEnableOption "common desktop options";
  };

  config = mkIf cfg.enable {
    # enable option sets
    nixfiles = {
      profile.base.enable = true;
      packageSets.multimedia.enable = mkDefault true;
      programs.syncthing.enable = mkDefault true;
      hardware = {
        bluetooth.enable = mkDefault true;
        sound.enable = mkDefault true;
      };
    };

    # Enable the X11 windowing system.
    services.xserver.enable = true;

    environment.systemPackages = with pkgs; [
      arc-theme
      wl-clipboard
    ];

    # Enable flatpak
    services.flatpak.enable = mkDefault true;

    # Enable CUPS to print documents.
    services.printing.enable = mkDefault true;

    fonts.packages = with pkgs; [
      (nerdfonts.override { fonts = [ "FiraCode" ]; })
      noto-fonts-cjk
      (outputs.packages.${pkgs.system}.google-fonts.override { fonts = [ "NovaSquare" ];})
    ];

    # TODO this should be defined in home-manager or not at all probably
    # FIXME also my name is hardcoded
    users.users.nullbite = {
      packages = with pkgs; [
        firefox
      ];
    };
  };
}
