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
  ];

  # Enable flatpak
  services.flatpak.enable = true;

  # Enable CUPS to print documents.
  services.printing.enable = true;

  fonts.packages = with pkgs; [
    nerdfonts
    fira-code-nerdfont
  ];

  users.users.nullbite = {
    packages = with pkgs; [
      firefox
    ];
  };
}
