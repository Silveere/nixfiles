{ config, lib, pkgs, ...}:

{
  imports = [
    ./desktop-common.nix
  ];

  services.xserver.displayManager.sddm.enable = true;
  services.xserver.desktopManager.plasma5.enable = true;

  environment.systemPackages = with pkgs; [
    # this fixes tiny file dialogs for Minecraft
    libsForQt5.kdialog
  ];
}
