{ config, lib, pkgs, ...}:

{
  imports = [
    ./base.nix
    ../fragments/sound.nix
    ../fragments/multimedia.nix
  ];
  
  # Enable the X11 windowing system.
  services.xserver.enable = true;

  services.xserver.displayManager.sddm.enable = true;
  services.xserver.desktopManager.plasma5.enable = true;

  environment.systemPackages = with pkgs; [
    arc-theme
  ];

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
