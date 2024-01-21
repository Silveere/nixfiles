{ config, lib, pkgs, ...}:

{
  imports = [
    ./base.nix
    ./fragments/sound.nix
    ./fragments/multimedia.nix
    ./fragments/software/syncthing.nix
    ./fragments/hardware/bluetooth.nix
  ];
  
  # Enable the X11 windowing system.
  services.xserver.enable = true;

  environment.systemPackages = with pkgs; [
    arc-theme
    wl-clipboard
  ];

  # Enable flatpak
  services.flatpak.enable = true;

  # Enable CUPS to print documents.
  services.printing.enable = true;

  fonts.packages = with pkgs; [
    (nerdfonts.override { fonts = [ "FiraCode" ]; })
  ];

  users.users.nullbite = {
    packages = with pkgs; [
      firefox
    ];
  };
}
