{ config, lib, pkgs, ...}:

{
  imports = [
    ./base.nix
    ../fragments/sound.nix
  ];
  
  # Enable the X11 windowing system.
  services.xserver.enable = true;

  services.xserver.displayManager.sddm.enable = true;
  services.xserver.desktopManager.plasma5.enable = true;

  # Enable flatpak
  services.flatpak.enable = true;

  # Enable CUPS to print documents.
  services.printing.enable = true;

  users.users.nullbite = {
    packages = with pkgs; [
      firefox
    ];
  };
}
